"""
Handles Http server related functionality, manages requests and responses and their logging.
"""
module AppServer

using Revise, HTTP, HTTP.IOExtras, HTTP.Sockets, Millboard, MbedTLS, WebSockets, URIParser, Sockets, Distributed
using Genie, Genie.Router, Genie.Logger, Genie.Sessions, Genie.Configuration, Genie.WebChannels


"""
    startup(port::Int = 8000)

Starts the web server on the configurated port.
Automatically invoked when Genie is started with the `s` or the `server:start` command line params.

# Examples
```julia
julia> AppServer.startup()
Listening on 0.0.0.0:8000...
```
"""
function startup(port::Int = 8000, host = "127.0.0.1"; ws_port = port + 1)
  web_server = HTTP.Servers.Server((req) -> begin
    setup_http_handler(req, req.response)
  end, devnull)
  @async HTTP.Servers.serve(web_server, host, port)

  if Genie.config.websocket_server
    @async HTTP.listen(host, ws_port) do req
      if HTTP.WebSockets.is_upgrade(req.message)
        HTTP.WebSockets.upgrade(req) do ws
          setup_ws_handler(req.message, ws)
        end
      end
    end
  end
end


"""
"""
function setup_http_handler(req, res)
  try
    @fetch handle_request(req, res)
  catch ex
    Genie.Logger.log(string(ex), :critical)
    Genie.Logger.log(sprint(io->Base.show_backtrace(io, catch_backtrace() )), :critical)
    Genie.Logger.log("$(@__FILE__):$(@__LINE__)", :critical)

    message = Genie.Configuration.is_prod() ?
                "The error has been logged and we'll look into it ASAP." :
                string(ex, " in $(@__FILE__):$(@__LINE__)", "\n\n", sprint(io->Base.show_backtrace(io, catch_backtrace())))

    Genie.Router.serve_error_file(500, message, Genie.Router.@params)
  end
end


"""
"""
function setup_ws_handler(req, ws_client)
  while ! eof(ws_client)
    write(ws_client, String(@fetch handle_ws_request(req, String(readavailable(ws_client)), ws_client)))
  end
end


"""
    handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response

Http server handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = ip"0.0.0.0") :: HTTP.Response
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

    app_response.headers = merge(res.headers, Genie.config.cors_headers)
  end

  app_response.headers = [d for d in merge(Dict(res.headers), Dict(app_response.headers))]

  # app_response.cookies = merge(res.cookies, app_response.cookies)

  app_response
end


"""
    handle_ws_request(req::Request, client::Client, ip::IPv4 = ip"0.0.0.0") :: String

Http server handler function - invoked when the server gets a request.
"""
function handle_ws_request(req, msg::String, ws_client, ip::IPv4 = ip"0.0.0.0") :: String
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
