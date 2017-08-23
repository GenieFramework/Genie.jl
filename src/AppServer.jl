"""
Handles HttpServer related functionality, manages requests and responses and their logging.
"""
module AppServer

using HttpServer, Router, Genie, Millboard, Logger, Sessions, Configuration, MbedTLS, WebSockets, Channels, App, URIParser


"""
    startup(port::Int = 8000) :: HttpServer.Server

Starts the web server on the configurated port.
Automatically invoked when Genie is started with the `s` or the `server:start` command line params.

# Examples
```julia
julia> AppServer.startup()
Listening on 0.0.0.0:8000...
```
"""
function startup(port::Int = 8000) :: Tuple{Task,HttpServer.Server}
  http = HttpHandler() do req::Request, res::Response
    try
      ip::IPv4 = App.config.lookup_ip ? task_local_storage(:ip) : ip"255.255.255.255"
      nworkers() == 1 ? handle_request(req, res, ip) : @fetch handle_request(req, res, ip)
    catch ex
      Logger.log(string(ex), :critical)
      Logger.log(sprint(io->Base.show_backtrace(io, catch_backtrace() )), :critical)
      Logger.log("$(@__FILE__):$(@__LINE__)", :critical)

      message = Configuration.is_prod() ?
                  "The error has been logged and we'll look into it ASAP." :
                  string(ex, " in $(@__FILE__):$(@__LINE__)", "\n\n", sprint(io->Base.show_backtrace(io, catch_backtrace())))

      return Router.serve_error_file(500, message)
    end
  end

  if App.config.websocket_server
    wsh = WebSocketHandler() do req::Request, ws_client::WebSockets.WebSocket
      while true
        response =  try
                      msg = read(ws_client)
                      ip::IPv4 = App.config.lookup_ip ? task_local_storage(:ip) : ip"255.255.255.255"

                      nworkers() == 1 ? handle_ws_request(req, String(msg), ws_client, ip) : @fetch handle_ws_request(req, String(msg), ws_client, ip)
                    catch ex
                      if typeof(ex) == WebSockets.WebSocketClosedError
                        Channels.unsubscribe_client(ws_client)

                        break
                      end

                      try
                        Logger.log(string(ex), :critical)
                        Logger.log("$(@__FILE__):$(@__LINE__)", :critical)

                        Configuration.is_prod() ? "The error has been logged and we'll look into it ASAP." : string(ex)
                      catch exx
                        print_with_color(:red, "One can not simply log an error")
                      end

                      break
                    end

        try
          write(ws_client, response)
        catch socket_exception
          Channels.unsubscribe_client(ws_client)

          break
        end
      end
    end
  end

  App.config.lookup_ip && (http.events["connect"] = (http_client) -> handle_connect(http_client))

  server = App.config.websocket_server ? Server(http, wsh) : Server(http)
  server_task = @async run(server, port)

  if App.config.run_as_server
    while true
      sleep(1_000_000)
    end
  end

  server_task, server
end


"""
    handle_connect(client::HttpServer.Client) :: Void

Connection callback for HttpServer. Stores the Request IP in the current task's local storage.
"""
function handle_connect(client::HttpServer.Client) :: Void
  try
    ip, port = getsockname(isa(client.sock, MbedTLS.SSLContext) ? client.sock.bio : client.sock)
    task_local_storage(:ip, ip)
  catch ex
    Logger.log("Failed getting IP address of request", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    task_local_storage(:ip, ip"255.255.255.255")
  end

  nothing
 end


"""
    handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response

HttpServer handler function - invoked when the server gets a request.
"""
function handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response
  App.config.log_requests && log_request(req)
  App.config.server_signature != "" && sign_response!(res)

  app_response::Response = Router.route_request(req, res, ip)
  app_response.headers = merge(res.headers, app_response.headers)
  app_response.cookies = merge(res.cookies, app_response.cookies)

  App.config.log_responses && log_response(req, app_response)

  app_response
end


"""
    handle_ws_request(req::Request, client::Client, ip::IPv4 = ip"0.0.0.0") :: Response

HttpServer handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::Request, msg::String, ws_client::WebSockets.WebSocket, ip::IPv4 = ip"0.0.0.0") :: String
  App.config.log_requests && log_request(req)

  Router.route_ws_request(req, msg, ws_client, ip)
end


"""
    sign_response!(res::Response) :: Response

Adds a signature header to the response using the value in `App.config.server_signature`.
If `App.config.server_signature` is empty, the header is not added.
"""
function sign_response!(res::Response) :: Response
  if ! isempty(App.config.server_signature)
    res.headers["Server"] = App.config.server_signature
  end

  res
end


"""
    log_request(req::Request) :: Void

Logs information about the request.
"""
function log_request(req::Request) :: Void
  if Router.is_static_file(req.resource)
    App.config.log_resources && log_request_response(req)
  elseif App.config.log_responses
    log_request_response(req)
  end

  nothing
end


"""
    log_response(req::Request, res::Response) :: Void

Logs information about the response.
"""
function log_response(req::Request, res::Response) :: Void
  if Router.is_static_file(req.resource)
    App.config.log_resources && log_request_response(res)
  elseif App.config.log_responses
    log_request_response(res)
  end

  nothing
end


"""
    log_request_response(req_res::Union{Request,Response}) :: Void

Helper function that logs `Request` or `Response` objects.
"""
function log_request_response(req_res::Union{Request,Response}) :: Void
  req_data = Dict{String,String}()
  response_is_error = false

  for f in fieldnames(req_res)
    f = string(f)
    v = getfield(req_res, Symbol(f))

    f == "status" && (req_res.status == 404 || req_res.status == 500) && (response_is_error = true)

    req_data[f] = if f == "data" && ! isempty(v)
                    mapreduce(x -> string(Char(Int(x))), *, v) |> Logger.truncate_logged_output
                  elseif isa(v, Dict) && App.config.log_formatted
                    Millboard.table(parse_inner_dict(v)) |> string
                  else
                    string(v) |> Logger.truncate_logged_output
                  end
  end

  Logger.log(string(req_res) * "\n" * string(App.config.log_formatted ? Millboard.table(req_data) : req_data), response_is_error ? :err : :debug, showst = false)

  nothing
end


"""
    parse_inner_dict{K,V}(d::Dict{K,V}) :: Dict{String,String}

Helper function that knows how to parse a `Dict` containing `Request` or `Response` data and prepare it for being logged.
"""
function parse_inner_dict{K,V}(d::Dict{K,V}) :: Dict{String,String}
  r = Dict{String,String}()
  for (k, v) in d
    k = string(k)
    if k == "Cookie" && App.config.log_verbosity == Configuration.LOG_LEVEL_VERBOSITY_VERBOSE
      cookie = Dict{String,String}()
      cookies = split(v, ";")
      for c in cookies
        cookie_part = split(c, "=")
        cookie[cookie_part[1]] = cookie_part[2] |> Logger.truncate_logged_output
      end

      r[k] = (App.config.log_formatted ? Millboard.table(cookie) : cookie) |> string
    else
      r[k] = Logger.truncate_logged_output(string(v))
    end
  end

  r
end

end
