"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

using Revise, HTTP, HTTP.IOExtras, HTTP.Sockets, Millboard, MbedTLS, URIParser, Sockets, Distributed
using Genie, Genie.Configuration, Genie.Loggers, Genie.Sessions, Genie.Flax, Genie.Router, Genie.WebChannels


"""
    startup(port::Int = 8000)

Starts the web server on the configured port.
```
"""
function startup(port::Int = 8000, host::String = Genie.config.server_host;
                  ws_port::Int = port + 1, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing)

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

  if async
    log("Web Server starting at $host:$port")
    @async command()
    log("Web Server running at $host:$port")
  else
    log("Web Server starting at $host:$port")
    command()
    log("Web Server stopped")
  end
end


"""
"""
function setup_http_handler(req::HTTP.Request, res::HTTP.Response = HTTP.Response()) :: HTTP.Response
  try
    @fetch handle_request(req, res)
  catch ex
    error_message = string(sprint(showerror, ex), "\n\n")

    log(error_message, :critical)

    message = Genie.Configuration.is_prod() ?
                "The error has been logged and we'll look into it ASAP." :
                string(error_message, " in $(@__FILE__):$(@__LINE__)", "\n\n")

    Genie.Router.error_500(message, req)
  end
end


"""
"""
function setup_ws_handler(req, ws_client) :: Nothing
  while ! eof(ws_client)
    write(ws_client, String(@fetch handle_ws_request(req, String(readavailable(ws_client)), ws_client)))
  end

  nothing
end


"""
    handle_request(req::Request, res::Response, ip::IPv4 = Genie.config.server_host) :: Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response
  Genie.config.server_signature != "" && sign_response!(res)
  set_headers!(req, res, Genie.Router.route_request(req, res, ip))
end


function set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  if req.method == Genie.Router.OPTIONS
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])

    ! isempty(Genie.config.cors_allowed_origins) &&
      in(req.headers["Origin"], Genie.config.cors_allowed_origins) &&
      (Genie.config.cors_headers["Access-Control-Allow-Origin"] == "" ||
        Genie.config.cors_headers["Access-Control-Allow-Origin"] == "*") &&
      (Genie.config.cors_headers["Access-Control-Allow-Origin"] = req.headers["Origin"])

    app_response.headers = [d for d in merge(Genie.config.cors_headers, Dict(res.headers))]
  end

  app_response.headers = vcat(app_response.headers, [d for d in merge(Dict(res.headers), Dict(app_response.headers))]) |> unique

  # app_response.cookies = merge(res.cookies, app_response.cookies)

  app_response
end


"""
    handle_ws_request(req::Request, client::Client, ip::IPv4 = Genie.config.server_host) :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request, msg::String, ws_client, ip::IPv4 = IPv4(Genie.config.server_host)) :: String
  msg == "" && return "" # keep alive
  Genie.Router.route_ws_request(req, msg, ws_client, ip)
end


"""
    sign_response!(res::Response) :: Response

Adds a signature header to the response using the value in `Genie.config.server_signature`.
If `Genie.config.server_signature` is empty, the header is not added.
"""
function sign_response!(res::HTTP.Response) :: HTTP.Response
  headers = Dict(res.headers)
  isempty(Genie.config.server_signature) || (headers["Server"] = Genie.config.server_signature)

  res.headers = [k for k in headers]
  res
end

end
