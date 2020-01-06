"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

import Revise
import HTTP, HTTP.IOExtras, HTTP.Sockets
import Millboard, MbedTLS, URIParser, Sockets, Distributed, Logging
import Genie, Genie.Configuration, Genie.Sessions, Genie.Router, Genie.WebChannels, Genie.Exceptions, Genie.Headers

mutable struct ServersCollection
  webserver::Union{Task,Nothing}
  websockets::Union{Task,Nothing}
end

const SERVERS = ServersCollection(nothing, nothing)

### PRIVATE ###


"""
    startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websocket_port, async::Bool = ! Genie.config.run_as_server) :: ServersCollection

Starts the web server.

# Arguments
- `port::Int`: the port used by the web server
- `host::String`: the host used by the web server
- `ws_port::Int`: the port used by the Web Sockets server
- `async::Bool`: run the web server task asynchronously

# Examples
```julia-repl
julia> startup(8000, "0.0.0.0", async = false)
[ Info: Ready!
Web Server starting at http://0.0.0.0:8000
```
"""
function startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
                  ws_port::Int = Genie.config.websocket_port, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing,
                  server::Union{Sockets.TCPServer,Nothing} = nothing) :: ServersCollection

  if Genie.config.websocket_server
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


"""
    handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response, ip::Sockets.IPv4 = Sockets.IPv4(Genie.config.server_host)) :: HTTP.Response
  isempty(Genie.config.server_signature) && Headers.sign_response!(res)

  try
    req = Headers.normalize_headers(req)
  catch ex
    @error ex
  end

  try
    Headers.set_headers!(req, res, Genie.Router.route_request(req, res, ip))
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
      return Genie.Router.err(ex.captured.ex.message,
                              error_info = string(ex.captured.ex.code, " ", ex.captured.ex.info),
                              error_code = ex.captured.ex.code)
    end

    error_message = string(sprint(showerror, ex), "\n\n")
    @error error_message

    message = Genie.Configuration.isprod() ?
                "The error has been logged and we'll look into it ASAP." :
                error_message

    Genie.Router.error_500(message, req)
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


"""
"""
function keepalive(; host::String, protocol::String = "http", port::Int = 80, urls::Vector{String} = String[],
                      interval::Int = 60, delay::Int = 30, nap::Int = 2, silent::Bool = true)
  in(protocol, ["http", "https"]) || error("Protocol should be one of `http` or `https`")

  function ping(t::Timer)
    try
      for u in urls
        if ! isempty(u) && startswith(u, "/") && length(u) > 1
          u = u[2:end]
        elseif u == "/"
          u = ""
        end

        url = protocol * "://" * host * (port != 80 ? (":" * "$port") : "") * "/" * u

        if ! silent
          @info "Pinging $url"
          HTTP.get(url)
        else
          HTTP.get(url);
        end

        sleep(nap)
      end
    catch ex
      @error ex
    end
  end

  t = Timer(ping, delay, interval = interval)
  wait(t)

  t
end

end
