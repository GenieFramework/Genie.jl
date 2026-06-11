"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module Server

using HTTP, Sockets, HTTP.WebSockets
import Millboard, Distributed, Logging
import Genie
import Distributed
import HTTP: forceclose, startwrite, closeread, body_read!, body_close!
import HTTP.URI


"""
    ServersCollection(webserver::Union{Task,Nothing}, websockets::Union{Task,Nothing})

Represents a object containing references to Genie's web and websockets servers.
"""
Base.@kwdef mutable struct ServersCollection
  webserver::Union{T,Nothing} where T <: HTTP.Server = nothing
  websockets::Union{W,Nothing} where W <: HTTP.WebSockets.Server = nothing
end

"""
    SERVERS

ServersCollection constant containing references to the current app's web and websockets servers.
"""
const SERVERS = ServersCollection[]
const Servers = SERVERS


function isrunning(server::ServersCollection, prop::Symbol = :webserver) :: Bool
  isa(getfield(server, prop), Task) && ! istaskdone(getfield(server, prop))
end
function isrunning(prop::Symbol = :webserver) :: Bool
  isempty(SERVERS) ? false : isrunning(SERVERS[1], prop)
end

function server_status(server::ServersCollection, prop::Symbol) :: Nothing
  if isrunning(server, prop)
    @info("✔️ server is running.")
  else
    @error("❌ $server is not running.")
    isa(getfield(server, prop), Task) && fetch(getfield(server, prop))
  end

  nothing
end


"""
    up(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websockets_port, async::Bool = ! Genie.config.run_as_server) :: ServersCollection

Starts the web server.

# Arguments
- `port::Int`: the port used by the web server
- `host::String`: the host used by the web server
- `ws_port::Int`: the port used by the Web Sockets server
- `async::Bool`: run the web server task asynchronously

# Examples
```julia-repl
julia> up(8000, "127.0.0.1", async = false)
[ Info: Ready!
Web Server starting at http://127.0.0.1:8000
```
"""
function up(port::Int,
            host::String = Genie.config.server_host;
            ws_port::Union{Int,Nothing} = Genie.config.websockets_port,
            async::Bool = ! Genie.config.run_as_server,
            verbose::Bool = false,
            server::Union{Sockets.TCPServer,Nothing} = nothing,
            wsserver::Union{Sockets.TCPServer,Nothing} = server,
            open_browser::Bool = false,
            reuseaddr::Bool = true,
            updateconfig::Bool = true,
            protocol::String = "http",
            query::Dict = Dict(),
            http_kwargs...) :: ServersCollection

  if server !== nothing
    try
      socket_info = Sockets.getsockname(server)
      port = Int(socket_info[2])
      host = string(socket_info[1])
    catch ex
      @error "Failed parsing `server` parameter info."
      @error ex
    end
  end

  ws_port === nothing && (ws_port = port)

  updateconfig && update_config(port, host, ws_port)

  new_server = ServersCollection()

  if Genie.config.websockets_server !== nothing && port !== ws_port
    print_server_status("Web Sockets server starting at $host:$ws_port")
    new_server.websockets = HTTP.WebSockets.listen!(host, ws_port; check_origin=(req) -> true) do ws
      setup_ws_handler(ws)
    end
  elseif Genie.config.websockets_server !== nothing && port == ws_port
    print_server_status("Web Sockets available at $host:$port (via HTTP upgrade)")
  end

  command = () -> begin
    if server !== nothing
      HTTP.listen!(server; reuseaddr = reuseaddr, http_kwargs...) do stream::HTTP.Stream
        try
          setup_http_streamer(stream)
        catch ex
          @error "Error in HTTP stream handler" exception=(ex, catch_backtrace())
          isa(ex, Base.IOError) || rethrow(ex)
        end
      end
    else
      HTTP.listen!(host, port; reuseaddr = reuseaddr, http_kwargs...) do stream::HTTP.Stream
        try
          setup_http_streamer(stream)
        catch ex
          @error "Error in HTTP stream handler" exception=(ex, catch_backtrace())
          isa(ex, Base.IOError) || rethrow(ex)
        end
      end
    end
  end

  server_url = "$protocol://$host:$port"
  if ! isempty(query)
    server_url *= ("?" * join(["$(k)=$(v)" for (k, v) in query], "&"))
  end

  if async
    print_server_status("Web Server starting at $server_url")
  else
    print_server_status("Web Server starting at $server_url - press Ctrl/Cmd+C to stop the server.")
  end
  
  listener = command()

  if !async && !isnothing(listener)
    try
      if Base.isinteractive()
        wait(listener)
      else
        # interruptible version for non-interactive sessions
        Base.exit_on_sigint(false)
        while true
          sleep(0.5)
        end
      end
    catch e
      e isa InterruptException || @warn "Server error: $e"
      nothing
    finally
      close(listener)
      sleep(0.1)
      Base.isinteractive() || Base.exit_on_sigint(true)  # restore default behavior
      # close the corresponding websocket server
      new_server.websockets !== nothing && isopen(new_server.websockets) && close(new_server.websockets)
    end
  end

  if listener !== nothing && isopen(listener)
    new_server.webserver = listener

    try
      open_browser && openbrowser(server_url)
    catch ex
      @error "Failed to open browser"
      @error ex
    end
  end

  push!(SERVERS, new_server)

  new_server
end

function up(; port = Genie.config.server_port, ws_port = Genie.config.websockets_port, host = Genie.config.server_host, kwargs...) :: ServersCollection
  up(port, host; ws_port = ws_port, kwargs...)
end


print_server_status(status::String) = (println(); @info "$status \n")


@static if Sys.isapple()
  openbrowser(url::URI) = run(`open $url`)
elseif Sys.islinux()
  openbrowser(url::URI) = run(`xdg-open $url`)
elseif Sys.iswindows()
  openbrowser(url::URI) = run(`cmd /C start $url`)
end

function openbrowser(target::AbstractString = ""; port::Int = Genie.config.server_port)
  uri = URI(target)
  isempty(uri.port) || (port = uri.port)
  host = isempty(uri.host) ? "localhost" : uri.host
  scheme = isempty(uri.scheme) ? "http" : uri.scheme
  uri = URI("$scheme://$host:$port$(uri.path)$(isempty(uri.query) ? "" : "?" * uri.query)")
  
  openbrowser(uri)
end

"""
    serve(path::String = pwd(), params...; kwparams...)

Serves a folder of static files located at `path`. Allows Genie to be used as a static files web server.
The `params` and `kwparams` arguments are forwarded to `Genie.up()`.

# Arguments
- `path::String`: the folder of static files to be served by the server
- `params`: additional arguments which are passed to `Genie.up` to control the web server
- `kwparams`: additional keyword arguments which are passed to `Genie.up` to control the web server

# Examples
```julia-repl
julia> Genie.serve("public", 8888, async = false, verbose = true)
[ Info: Ready!
2019-08-06 16:39:20:DEBUG:Main: Web Server starting at http://127.0.0.1:8888
[ Info: Listening on: 127.0.0.1:8888
[ Info: Accept (1):  🔗    0↑     0↓    1s 127.0.0.1:8888:8888 ≣16
```
"""
function serve(path::String = pwd(), params...; kwparams...)
  path = abspath(path)

  Genie.config.server_document_root = path

  Genie.Router.route("/") do
    Genie.Router.serve_static_file(path; root = path)
  end
  Genie.Router.route(".*") do
    Genie.Router.serve_static_file(Genie.Router.params(:REQUEST).target; root = path)
  end

  up(params...; kwparams...)
end


"""
    update_config(port::Int, host::String, ws_port::Int) :: Nothing

Updates the corresponding Genie configurations to the corresponding values for
  `port`, `host`, and `ws_port`, if these are passed as arguments when starting up the server.
"""
function update_config(port::Int, host::String, ws_port::Int) :: Nothing
  if port !== Genie.config.server_port && ws_port === Genie.config.websockets_port
    Genie.config.websockets_port = port
  elseif ws_port !== Genie.config.websockets_port
    Genie.config.websockets_port = ws_port
  end

  Genie.config.server_port = port
  Genie.config.server_host = host

  nothing
end


"""
    down(; webserver::Bool = true, websockets::Bool = true) :: ServersCollection

Shuts down the servers optionally indicating which of the `webserver` and `websockets` servers to be stopped.
It does not remove the servers from the `SERVERS` collection. Returns the collection.
"""
function down(; webserver::Bool = true, websockets::Bool = true, force::Bool = true) :: Vector{ServersCollection}
  for i in 1:length(SERVERS)
    down(SERVERS[i]; webserver, websockets, force)
  end

  # CRITICAL: Close idle HTTP client connections to prevent "Connection reset by peer"
  # errors when restarting servers on the same port. HTTP.jl v2 maintains a connection
  # pool that can try to reuse connections from a previous server instance.
  try
    HTTP.close_idle_connections!(HTTP._default_client!().transport)
  catch ex
    @debug "Error closing idle HTTP connections: $ex"
  end

  SERVERS
end


function down(server::ServersCollection; webserver::Bool = true, websockets::Bool = true, force::Bool = false) :: ServersCollection
  if webserver && !isnothing(server.webserver)
    try
      # First, clean up WebChannels to close all websocket connections
      try
        Genie.WebChannels.unsubscribe_disconnected_clients()
      catch
        # May error if WebChannels not loaded
      end

      if force
        forceclose(server.webserver)
      else
        close(server.webserver)
      end

      # Give the OS time to fully release the socket binding
      # This prevents "Address already in use" errors when tests restart servers quickly
      sleep(0.1)
    catch ex
      @debug "Error closing webserver: $ex"
    end
  end

  if websockets && !isnothing(server.websockets)
    try
      close(server.websockets)
    catch ex
      @debug "Error closing websocket server: $ex"
    end
  end

  server
end


"""
    function down!(; webserver::Bool = true, websockets::Bool = true) :: Vector{ServersCollection}

Shuts down all the servers and empties the `SERVERS` collection. Returns the empty collection.
"""
function down!() :: Vector{ServersCollection}
  down()
  empty!(SERVERS)

  SERVERS
end


"""
    handle_request(req::HTTP.Request, res::HTTP.Response) :: HTTP.Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response; stream::Union{HTTP.Stream,Nothing} = nothing) :: HTTP.Response
  try
    req = Genie.Headers.normalize_headers(req)
  catch ex
    @error ex
  end

  try
    Genie.Headers.set_headers!(req, res, Genie.Router.route_request(req, res; stream))
  catch ex
    rethrow(ex)
  end
end


function streamhandler(handler::Function)
    return function(stream::HTTP.Stream)
        try
            request::HTTP.Request = stream.message
            body_bytes = read(stream)

            # In HTTP.jl v2, Request is parameterized by body type, so we need to create a new one with the correct body
            body = isempty(body_bytes) ? HTTP.EmptyBody() : HTTP.BytesBody(body_bytes)
            request = HTTP.Request(
                request.method,
                request.target;
                headers=request.headers,
                trailers=request.trailers,
                body=body,
                host=request.host,
                content_length=length(body_bytes),
                proto_major=request.proto_major,
                proto_minor=request.proto_minor,
                close=request.close,
                context=HTTP.get_request_context(request)
            )

            closeread(stream)

            # In HTTP.jl v2, Request no longer has a response field
            # Get the response from the handler and set it on the stream
            response::HTTP.Response = handler(request; stream)
            response.request = request
            stream.response = response

            startwrite(stream)

            # Write the response body properly based on its type
            body = response.body
            if body isa AbstractString
                write(stream, body)
            elseif body isa AbstractVector{UInt8}
                write(stream, body)
            elseif body isa HTTP.AbstractBody
                buf = Vector{UInt8}(undef, 16 * 1024)
                try
                    while true
                        n = HTTP.body_read!(body, buf)
                        n == 0 && break
                        write(stream, @view(buf[1:n]))
                    end
                finally
                    try
                        HTTP.body_close!(body)
                    catch
                        # Ignore close errors
                    end
                end
            else
                error("Unsupported body type: $(typeof(body))")
            end

            return
        catch ex
            @error "Error in streamhandler" exception=(ex, catch_backtrace())
            rethrow(ex)
        end
    end
end


function setup_http_streamer(stream::HTTP.Stream)
  if Genie.config.websockets_server !== nothing && HTTP.WebSockets.isupgrade(stream.message)
    HTTP.WebSockets.upgrade(stream; check_origin=(req) -> true) do ws
      setup_ws_handler(ws)
    end
  else
    if Genie.config.features_peerinfo
      try
        task_local_storage(:peer, Sockets.getpeername( HTTP.IOExtras.tcpsocket(HTTP.Streams.getrawstream(stream)) ))
      catch ex
        @error ex
      end
    end
    streamhandler(setup_http_listener)(stream)
  end
end


"""
    setup_http_listener(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response

Configures the handler for the HTTP Request and handles errors.
"""
function setup_http_listener(req::HTTP.Request, res::HTTP.Response = HTTP.Response(); stream::Union{HTTP.Stream, Nothing} = nothing) :: HTTP.Response
  try
    Distributed.@fetch handle_request(req, res; stream)
  catch ex # ex is a Distributed.RemoteException
    if isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, Genie.Exceptions.RuntimeException)

      @error ex.captured.ex
      return Genie.Router.error(ex.captured.ex.code, ex.captured.ex.message, Genie.Router.response_mime(),
                              error_info = string(ex.captured.ex.code, " ", ex.captured.ex.info))
    end

    error_message = string(sprint(showerror, ex), "\n\n")
    @error error_message

    message = Genie.Configuration.isprod() ?
                "The error has been logged and we'll look into it ASAP." :
                error_message

    Genie.Router.error(message, Genie.Router.response_mime(), Val(500))
  end
end


"""
    setup_ws_handler(ws::HTTP.WebSockets.WebSocket) :: Nothing

Handles WebSocket connections. The handshake request is available as `ws.handshake_request`.
"""
function setup_ws_handler(ws::HTTP.WebSockets.WebSocket) :: Nothing
  # In HTTP.jl v2, the handshake request is stored in the WebSocket object
  req = ws.handshake_request

  try
    while ! HTTP.WebSockets.isclosed(ws)
      message = HTTP.WebSockets.receive(ws)
      response = Distributed.@fetch handle_ws_request(req; message = message, client = ws)
      # Check if WebSocket is still open before sending (client might have disconnected during processing)
      HTTP.WebSockets.isclosed(ws) && break
      HTTP.WebSockets.send(ws, response)
    end
  catch ex
    # Handle WebSocketError (normal close or protocol error)
    if isa(ex, HTTP.WebSockets.WebSocketError)
      # Check if it's a normal/expected close (1000, 1001, 1005, 1006)
      if ex.message.code in (1000, 1001, 1005, 1006)
        Genie.WebChannels.unsubscribe_client(ws)
        return nothing
      end
      @error "WebSocket error" exception=(ex, catch_backtrace())
      Genie.WebChannels.unsubscribe_client(ws)
      return nothing
    # Handle RemoteException wrapping CloseFrameBody
    elseif isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, HTTP.WebSockets.CloseFrameBody)
      Genie.WebChannels.unsubscribe_client(ws)
      return nothing
    # Handle RemoteException wrapping RuntimeException
    elseif isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, Genie.Exceptions.RuntimeException)
      @error ex.captured.ex
      Genie.WebChannels.unsubscribe_client(ws)
      return nothing
    else
      @error "WebSocket handler error" exception=(ex, catch_backtrace())
      Genie.WebChannels.unsubscribe_client(ws)
    end
  end

  nothing
end


"""
    handle_ws_request(req::HTTP.Request, msg::String, ws_client) :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request; message::Union{String,Vector{UInt8}}, client::HTTP.WebSockets.WebSocket) :: String
  isempty(message) && return "" # keep alive
  Genie.Router.route_ws_request(req, message, client)
end

end