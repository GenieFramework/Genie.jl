"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module Server

using HTTP, Sockets, HTTP.WebSockets
import Millboard, Distributed, Logging
import Genie
import Distributed
import HTTP.Servers: Listener, forceclose


"""
    ServersCollection(webserver::Union{Task,Nothing}, websockets::Union{Task,Nothing})

Represents a object containing references to Genie's web and websockets servers.
"""
Base.@kwdef mutable struct ServersCollection
  webserver::Union{T,Nothing} where T <: HTTP.Server = nothing
  websockets::Union{T,Nothing} where T <: HTTP.Server = nothing
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
            ratelimit::Union{Rational{Int},Nothing} = nothing,
            server::Union{Sockets.TCPServer,Nothing} = nothing,
            wsserver::Union{Sockets.TCPServer,Nothing} = server,
            open_browser::Bool = false,
            reuseaddr::Bool = Distributed.nworkers() > 1,
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

    new_server.websockets = HTTP.listen!(host, ws_port; verbose = verbose, rate_limit = ratelimit, server = wsserver,
                                                reuseaddr = reuseaddr, http_kwargs...) do http::HTTP.Stream
      if HTTP.WebSockets.isupgrade(http.message)
        HTTP.WebSockets.upgrade(http) do ws
          setup_ws_handler(http, ws)
        end
      end
    end
  end

  command = () -> begin
    HTTP.listen!(parse(Sockets.IPAddr, host), port; verbose = verbose, rate_limit = ratelimit, server = server,
                                    reuseaddr = reuseaddr, http_kwargs...) do stream::HTTP.Stream
      try
        if Genie.config.websockets_server !== nothing && port === ws_port && HTTP.WebSockets.isupgrade(stream.message)
          HTTP.WebSockets.upgrade(stream) do ws
            setup_ws_handler(stream, ws)
          end
        else
          setup_http_streamer(stream)
        end
      catch ex
        isa(ex, Base.IOError) || @error ex
        nothing
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
  
  listener = try
    command()
  catch
    nothing
  end
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
  openbrowser(url::String) = run(`open $url`)
elseif Sys.islinux()
  openbrowser(url::String) = run(`xdg-open $url`)
elseif Sys.iswindows()
  openbrowser(url::String) = run(`cmd /C start $url`)
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

  SERVERS
end


function down(server::ServersCollection; webserver::Bool = true, websockets::Bool = true, force::Bool = true) :: ServersCollection
  close_cmd = force ? forceclose : close
  webserver && !isnothing(server.webserver) && isopen(server.webserver) && close_cmd(server.webserver)
  websockets && !isnothing(server.websockets) && isopen(server.websockets) && close_cmd(server.websockets)

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
        request::HTTP.Request = stream.message
        request.body = read(stream)

        closeread(stream)
        request.response::HTTP.Response = handler(request; stream)
        request.response.request = request

        startwrite(stream)
        write(stream, request.response.body)

        return
    end
end


function setup_http_streamer(stream::HTTP.Stream)
  if Genie.config.features_peerinfo
    try
      task_local_storage(:peer, Sockets.getpeername( HTTP.IOExtras.tcpsocket(HTTP.Streams.getrawstream(stream)) ))
    catch ex
      @error ex
    end
  end

  streamhandler(setup_http_listener)(stream)
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
    setup_ws_handler(stream::HTTP.Stream, ws_client) :: Nothing

Configures the handler for WebSockets requests.
"""
function setup_ws_handler(stream::HTTP.Stream, ws_client) :: Nothing
  req = stream.message

  try
    req = stream.message

    while ! HTTP.WebSockets.isclosed(ws_client) && ! ws_client.writeclosed && isopen(ws_client.io)
      Sockets.send(ws_client, Distributed.@fetch handle_ws_request(req; message = HTTP.WebSockets.receive(ws_client), client = ws_client))
    end
  catch ex
    if isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, HTTP.WebSockets.CloseFrameBody) # && ex.captured.ex.code == 1000

      @info "WebSocket closed"

      return nothing
    elseif isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, Genie.Exceptions.RuntimeException)

      @error ex.captured.ex

      return nothing
    end

    # rethrow(ex)
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