"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

import HTTP, HTTP.IOExtras, HTTP.Sockets
import Millboard, URIParser, Sockets, Distributed, Logging, MbedTLS
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

### PRIVATE ###


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
                  open_browser::Bool = Genie.Configuration.isdev(),
                  http_kwargs...) :: ServersCollection

  update_config(port, host, ws_port)

  if Genie.config.websockets_server && port != ws_port
    SERVERS.websockets = @async HTTP.listen(host, ws_port; verbose = verbose, rate_limit = ratelimit, server = wsserver, sslconfig = ssl_config, http_kwargs...) do http::HTTP.Stream
      if HTTP.WebSockets.is_upgrade(http.message)
        HTTP.WebSockets.upgrade(http) do ws
          setup_ws_handler(http.message, ws)
        end
      end
    end

    print_server_status("Web Sockets server running at $host:$ws_port")
  end

  command = () -> begin
    HTTP.listen(parse(Sockets.IPAddr, host), port; verbose = verbose, rate_limit = ratelimit, server = server, sslconfig = ssl_config, http_kwargs...) do http::HTTP.Stream
      if Genie.config.websockets_server && port == ws_port && HTTP.WebSockets.is_upgrade(http.message)
        HTTP.WebSockets.upgrade(http) do ws
          setup_ws_handler(http.message, ws)
        end
      else
        HTTP.handle(HTTP.RequestHandlerFunction(setup_http_handler), http)
      end
    end
  end

  server_url = "$( (ssl_config !== nothing && Genie.config.ssl_enabled) ? "https" : "http" )://$host:$port"


  status = if async
    @async command()
  else
    command()
  end

  @info status

  if status.state == :runnable
    SERVERS.webserver = status
    print_server_status("Web Server running at $server_url")
    open_browser && openbrowser(server_url)
  end

  SERVERS
end

function startup(; port = Genie.config.server_port, ws_port = Genie.config.websockets_port, kwargs...) :: ServersCollection
    startup(port; ws_port = ws_port, kwargs...)
end

const up = startup


print_server_status(status::String) = printstyled("\n $status \n", color = :light_blue, bold = true)


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
    handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response, ip::Sockets.IPv4 = Sockets.IPv4(Genie.config.server_host)) :: HTTP.Response
  try
    req = Genie.Headers.normalize_headers(req)
  catch ex
    @error ex
  end

  try
    Genie.Headers.set_headers!(req, res, Genie.Router.route_request(req, res, ip))
  catch ex
    @error ex
    rethrow(ex)
  end
end


"""
    setup_http_handler(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response

Configures the handler for the HTTP Request and handles errors.
"""
function setup_http_handler(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response
  try
    Distributed.@fetch handle_request(req, res)
  catch ex # ex is a Distributed.RemoteException
    if isa(ex, Distributed.RemoteException) &&
        isa(ex.captured, Distributed.CapturedException) &&
          isa(ex.captured.ex, Genie.Exceptions.RuntimeException)

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
  while ! eof(ws_client)
    write(ws_client, String(Distributed.@fetch handle_ws_request(req, String(readavailable(ws_client)), ws_client)))
  end

  nothing
end


"""
    handle_ws_request(req::HTTP.Request, msg::String, ws_client, ip::IPv4 = IPv4(Genie.config.server_host)) :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request, msg::String, ws_client, ip::Sockets.IPv4 = Sockets.IPv4(Genie.config.server_host)) :: String
  msg == "" && return "" # keep alive
  Genie.Router.route_ws_request(req, msg, ws_client, ip)
end

end
