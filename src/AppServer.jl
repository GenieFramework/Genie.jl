"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

import Revise
import HTTP, HTTP.IOExtras, HTTP.Sockets
import Millboard, URIParser, Sockets, Distributed, Logging
import Genie

mutable struct ServersCollection
  webserver::Union{Task,Nothing}
  websockets::Union{Task,Nothing}
end

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
julia> startup(8000, "127.0.0.1", async = false)
[ Info: Ready!
Web Server starting at http://127.0.0.1:8000
```
"""
function startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
                  ws_port::Int = Genie.config.websockets_port, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing,
                  server::Union{Sockets.TCPServer,Nothing} = nothing) :: ServersCollection

  update_config(port, host, ws_port)

  if Genie.config.websockets_server
    SERVERS.websockets = @async HTTP.listen(host, ws_port) do req
      if HTTP.WebSockets.is_upgrade(req.message)
        HTTP.WebSockets.upgrade(req) do ws
          setup_ws_handler(req.message, ws)
        end
      end
    end

    printstyled("Web Sockets server running at $host:$ws_port \n", color = :light_blue, bold = true)
  end

  command = () -> begin
    HTTP.serve(parse(Sockets.IPAddr, host), port, verbose = verbose, rate_limit = ratelimit, server = server) do req::HTTP.Request
      setup_http_handler(req)
    end
  end

  printstyled("Web Server starting at http://$host:$port \n", color = :light_blue, bold = true)

  if async
    SERVERS.webserver = @async command()
    printstyled("Web Server running at http://$host:$port \n", color = :light_blue, bold = true)
  else
    SERVERS.webserver = command()
    printstyled("Web Server stopped \n", color = :light_blue, bold = true)
  end

  SERVERS
end


function update_config(port::Int, host::String, ws_port::Int) :: Nothing
  Genie.config.server_port = port
  Genie.config.server_host = host
  Genie.config.websockets_port = ws_port

  nothing
end


function down(; webserver::Bool = true, websockets::Bool = true) :: ServersCollection
  webserver && (@async Base.throwto(SERVERS.webserver, InterruptException()))
  websockets && (@async Base.throwto(SERVERS.websockets, InterruptException()))

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
