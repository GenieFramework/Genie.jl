"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

using Revise, HTTP, HTTP.IOExtras, HTTP.Sockets, Millboard, MbedTLS, URIParser, Sockets, Distributed
using Genie, Genie.Configuration, Genie.Loggers, Genie.Sessions, Genie.Flax, Genie.Router, Genie.WebChannels


### PRIVATE ###


"""
    startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websocket_port, async::Bool = ! Genie.config.run_as_server) :: Nothing

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
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing) :: Nothing

  # Create log directory and log file
  Genie.config.log_to_file && Loggers.initlogfile()

  # Create build folders
  Genie.config.flax_compile_templates && Flax.create_build_folders()

  if Genie.config.websocket_server
    @async HTTP.listen(host, ws_port) do req
      if HTTP.WebSockets.is_upgrade(req.message)
        HTTP.WebSockets.upgrade(req) do ws
          setup_ws_handler(req.message, ws)
        end
      end
    end

    log("Web Sockets server running at $host:$ws_port")
  end

  command = () -> begin
    HTTP.serve(parse(IPAddr, host), port, verbose = verbose, rate_limit = ratelimit) do req::HTTP.Request
      setup_http_handler(req)
    end
  end

  @info "Ready!\n"
  log("Web Server starting at http://$host:$port")

  if async
    @async command()
    log("Web Server running at http://$host:$port")
  else
    command()
    log("Web Server stopped")
  end

  nothing
end


"""
    setup_http_handler(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response

Configures the handler for the HTTP Request and handles errors.
"""
@inline function setup_http_handler(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response
  try
    @fetch handle_request(req, res)
  catch ex
    error_message = string(sprint(showerror, ex), "\n\n")

    log(error_message, :critical)

    message = Genie.Configuration.isprod() ?
                "The error has been logged and we'll look into it ASAP." :
                string(error_message, " in $(@__FILE__):$(@__LINE__)", "\n\n")

    Genie.Router.error_500(message, req)
  end
end


"""
    setup_ws_handler(req::HTTP.Request, ws_client) :: Nothing

Configures the handler for WebSockets requests.
"""
@inline function setup_ws_handler(req::HTTP.Request, ws_client) :: Nothing
  while ! eof(ws_client)
    write(ws_client, String(@fetch handle_ws_request(req, String(readavailable(ws_client)), ws_client)))
  end

  nothing
end


"""
    handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response

Http server handler function - invoked when the server gets a request.
"""
@inline function handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response
  isempty(Genie.config.server_signature) && sign_response!(res)
  set_headers!(req, res, Genie.Router.route_request(req, res, ip))
end


"""
    handle_ws_request(req::HTTP.Request, msg::String, ws_client, ip::IPv4 = IPv4(Genie.config.server_host)) :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request, msg::String, ws_client, ip::IPv4 = IPv4(Genie.config.server_host)) :: String
  msg == "" && return "" # keep alive
  Genie.Router.route_ws_request(req, msg, ws_client, ip)
end


"""
    set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response

Configures the response headers.
"""
function set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  if req.method == Genie.Router.OPTIONS || req.method == Genie.Router.GET
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])

    #=
    If the request origin matches an entry in the config's array of allowed origins,
    and the CORS header allowed origin is set to "" or "*", then overwrite the
    CORS header allowed origin with the request origin.
    =#
    ! isempty(Genie.config.cors_allowed_origins) &&
      in(Dict(req.headers)["Origin"], Genie.config.cors_allowed_origins) &&
      (Genie.config.cors_headers["Access-Control-Allow-Origin"] == "" ||
        Genie.config.cors_headers["Access-Control-Allow-Origin"] == "*") &&
      (Genie.config.cors_headers["Access-Control-Allow-Origin"] = Dict(req.headers)["Origin"])

    #=
    Combine headers. If different values for the same keys,
    use the following order of precedence:
    app_response > res > Genie.config

    The app_response likely has an automatically-determined
    response type header that we want to keep.
    =#
    app_response.headers = [d for d in merge(Genie.config.cors_headers, Dict(res.headers), Dict(app_response.headers))]
  end

  #=
  Combine headers. If different values for the same keys,
  use the following order of precedence:
  app_response > res
  =#
  app_response.headers = [d for d in merge(Dict(res.headers), Dict(app_response.headers))]

  app_response
end


"""
    sign_response!(res::HTTP.Response) :: HTTP.Response

Adds a signature header to the response using the value in `Genie.config.server_signature`.
If `Genie.config.server_signature` is empty, the header is not added.
"""
@inline function sign_response!(res::HTTP.Response) :: HTTP.Response
  headers = Dict(res.headers)
  isempty(Genie.config.server_signature) || (headers["Server"] = Genie.config.server_signature)

  res.headers = [k for k in headers]
  res
end

end
