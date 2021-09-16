"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

using HTTP, Sockets
import Millboard, Distributed, Logging, MbedTLS
import Genie

"""
    ServersCollection(webserver::Union{Task,Nothing}, websockets::Union{Task,Nothing})

Represents a object containing references to Genie's web and websockets servers.
"""
mutable struct ServersCollection
  webserver::Union{Task,Nothing}
  websockets::Union{Task,Nothing}
end

"""
    SERVERS

ServersCollection constant containing references to the current app's web and websockets servers.
"""
const SERVERS = ServersCollection(nothing, nothing)

function isinitialized(server::Symbol = :webserver) :: Bool
  getfield(SERVERS, server) !== nothing
end

function isrunning(server::Symbol = :webserver) :: Bool
  isinitialized(server) && ! istaskdone(getfield(SERVERS, server))
end

function upwebsockets(host::String = Genie.config.server_host; ws_port::Int = port,
                      verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing,
                      wsserver::Union{Sockets.TCPServer,Nothing} = nothing,
                      ssl_config::Union{MbedTLS.SSLConfig,Nothing} = Genie.config.ssl_config,
                      http_kwargs...) :: Nothing
  print_server_status("Web Sockets server starting at $host:$ws_port")

  SERVERS.websockets = @async HTTP.listen(host, ws_port; verbose = verbose, rate_limit = ratelimit, server = wsserver, sslconfig = ssl_config, http_kwargs...) do http::HTTP.Stream
    if HTTP.WebSockets.is_upgrade(http.message)
      HTTP.WebSockets.upgrade(http) do ws
        setup_ws_handler(http.message, ws)
      end
    end
  end

  server_status(:websockets)

  nothing
end

function server_status(server::Symbol) :: Nothing
  if isrunning(server)
    @info("✔️ $server is running.")
  else
    @error("❌ $server is not running.")
    isinitialized(server) && isa(getfield(SERVERS, server), Task) && fetch(getfield(SERVERS, server))
  end

  nothing
end

function upwebserver(port::Int, host::String = Genie.config.server_host;
                      ws_port::Int = port, async::Bool = ! Genie.config.run_as_server,
                      verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing,
                      server::Union{Sockets.TCPServer,Nothing} = nothing, wsserver::Union{Sockets.TCPServer,Nothing} = nothing,
                      ssl_config::Union{MbedTLS.SSLConfig,Nothing} = Genie.config.ssl_config,
                      open_browser::Bool = false,
                      http_kwargs...) :: Nothing
  command = () -> begin
    HTTP.listen(parse(Sockets.IPAddr, host), port; verbose = verbose, rate_limit = ratelimit, server = server, sslconfig = ssl_config, http_kwargs...) do http::HTTP.Stream
      try
        if Genie.config.websockets_server && port == ws_port && HTTP.WebSockets.is_upgrade(http.message)
          HTTP.WebSockets.upgrade(http) do ws
            setup_ws_handler(http.message, ws)
          end
        else
          setup_http_streamer(http)
        end
      catch ex
        isa(ex, Base.IOError) || @error ex
      end
    end
  end

  server_url = "$( (ssl_config !== nothing && Genie.config.ssl_enabled) ? "https" : "http" )://$host:$port"

  status = if async
    print_server_status("Web Server starting at $server_url")
    @async command()
  else
    print_server_status("Web Server starting at $server_url - press Ctrl/Cmd+C to stop the server.")
    command()
  end

  if status !== nothing && status.state == :runnable
    SERVERS.webserver = status

    try
      open_browser && openbrowser(server_url)
    catch ex
      @error "Failed to open browser"
      @error ex
    end
  end

  sleep(1)
  server_status(:webserver)

  nothing
end

"""
    startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
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
function startup(port::Int, host::String = Genie.config.server_host;
                  ws_port::Int = port, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing,
                  server::Union{Sockets.TCPServer,Nothing} = nothing, wsserver::Union{Sockets.TCPServer,Nothing} = nothing,
                  ssl_config::Union{MbedTLS.SSLConfig,Nothing} = Genie.config.ssl_config,
                  open_browser::Bool = false,
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

  update_config(port, host, ws_port)

  if Genie.config.websockets_server && port != ws_port
    if isrunning(:websockets)
      @warn("✖️ A WebSockets server is already up and running.")
    end

    upwebsockets(host; ws_port = ws_port, verbose = verbose, ratelimit = ratelimit, wsserver = wsserver, ssl_config = ssl_config, http_kwargs...)
  end

  if isrunning(:webserver)
    @warn("✖️ A web server is already up and running.")
  end

  upwebserver(port, host; ws_port = ws_port, async = async, verbose = verbose, ratelimit = ratelimit, server = server,
                ssl_config = ssl_config, open_browser = open_browser, http_kwargs...)

  SERVERS
end

function startup(; port = Genie.config.server_port, ws_port = Genie.config.websockets_port, kwargs...) :: ServersCollection
    startup(port; ws_port = ws_port, kwargs...)
end

const up = startup


print_server_status(status::String) = @info "\n$status \n"


@static if Sys.isapple()
  openbrowser(url::String) = run(`open $url`)
elseif Sys.islinux()
  openbrowser(url::String) = run(`xdg-open $url`)
elseif Sys.iswindows()
  openbrowser(url::String) = run(`cmd /C start $url`)
end


"""
    update_config(port::Int, host::String, ws_port::Int) :: Nothing

Updates the corresponding Genie configurations to the corresponding values for
  `port`, `host`, and `ws_port`, if these are passed as arguments when starting up the server.
"""
function update_config(port::Int, host::String, ws_port::Int) :: Nothing
  Genie.config.server_port = port
  Genie.config.server_host = host
  Genie.config.websockets_port = ws_port

  nothing
end


"""
    down(; webserver::Bool = true, websockets::Bool = true) :: ServersCollection

Shuts down the servers optionally indicating which of the `webserver` and `websockets` servers to be stopped.
"""
function down(; webserver::Bool = true, websockets::Bool = true) :: ServersCollection
  webserver && (@async Base.throwto(SERVERS.webserver, InterruptException()))
  isnothing(websockets) || (websockets && (@async Base.throwto(SERVERS.websockets, InterruptException())))

  SERVERS
end


"""
    handle_request(req::HTTP.Request, res::HTTP.Response) :: HTTP.Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response) :: HTTP.Response
  try
    req = Genie.Headers.normalize_headers(req)
  catch ex
    @error ex
  end

  try
    Genie.Headers.set_headers!(req, res, Genie.Router.route_request(req, res))
  catch ex
    rethrow(ex)
  end
end


function setup_http_streamer(http::HTTP.Stream)
  if Genie.config.features_peerinfo
    try
      task_local_storage(:peer, Sockets.getpeername( HTTP.IOExtras.tcpsocket(HTTP.Streams.getrawstream(http)) ))
    catch ex
      @error ex
    end
  end

  HTTP.handle(HTTP.RequestHandlerFunction(setup_http_listener), http)
end


"""
    setup_http_listener(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response

Configures the handler for the HTTP Request and handles errors.
"""
function setup_http_listener(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response
  try
    Distributed.@fetch handle_request(req, res)
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
    setup_ws_handler(req::HTTP.Request, ws_client) :: Nothing

Configures the handler for WebSockets requests.
"""
function setup_ws_handler(req::HTTP.Request, ws_client) :: Nothing
  try
    while ! eof(ws_client)
      write(ws_client, String(Distributed.@fetch handle_ws_request(req, String(readavailable(ws_client)), ws_client)))
    end
  catch ex
    if isa(ex, Distributed.RemoteException) &&
      hasfield(typeof(ex), :captured) && isa(ex.captured, Distributed.CapturedException) &&
        hasfield(typeof(ex.captured), :ex) && isa(ex.captured.ex, Genie.Exceptions.RuntimeException)
      @error ex.captured.ex
    end
  end

  nothing
end


"""
    handle_ws_request(req::HTTP.Request, msg::String, ws_client) :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request, msg::String, ws_client) :: String
  isempty(msg) && return "" # keep alive
  Genie.Router.route_ws_request(req, msg, ws_client)
end

end
