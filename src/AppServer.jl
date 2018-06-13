"""
Handles HttpServer related functionality, manages requests and responses and their logging.
"""
module AppServer

using Revise, HTTP, Genie.Router, Genie, Millboard, Genie.Logger, Genie.Sessions, Genie.Configuration, MbedTLS, WebSockets, Genie.Channels, URIParser


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
function startup(port::Int = 8000, host = "127.0.0.1")
  @async HTTP.listen(host, port) do req::HTTP.Request
    setup_http_handler(req, HTTP.Response())
  end
end


"""
"""
function setup_http_handler(req::HTTP.Request, res::HTTP.Response)
  try
    # ip::IPv4 = Genie.config.lookup_ip ? task_local_storage(:ip) : ip"255.255.255.255"
    nworkers() == 1 ?
      handle_request(req, res, ip"255.255.255.255") :
      @fetch handle_request(req, res, ip"255.255.255.255")
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
function setup_ws_handler(req::HTTP.Request, ws_client::WebSockets.WebSocket)
  while true
    response =  try
                  msg = read(ws_client)
                  ip::IPv4 = Genie.config.lookup_ip ? task_local_storage(:ip) : ip"255.255.255.255"

                  nworkers() == 1 ? handle_ws_request(req, String(msg), ws_client, ip) : @fetch handle_ws_request(req, String(msg), ws_client, ip)
                catch ex
                  if typeof(ex) == WebSockets.WebSocketClosedError
                    Genie.Channels.unsubscribe_client(ws_client)

                    break
                  end

                  try
                    Genie.Logger.log(string(ex), :critical)
                    Genie.Logger.log("$(@__FILE__):$(@__LINE__)", :critical)

                    Genie.Configuration.is_prod() ? "The error has been logged and we'll look into it ASAP." : string(ex)
                  catch exx
                    print_with_color(:red, "One can not simply log an error")
                  end

                  break
                end

    try
      write(ws_client, response)
    catch socket_exception
      Genie.Channels.unsubscribe_client(ws_client)

      break
    end
  end
end


"""
    handle_connect(client::HttpServer.Client) :: Nothing

Connection callback for HttpServer. Stores the Request IP in the current task's local storage.
"""
function handle_connect(client::HTTP.Client) :: Nothing
  try
    ip, port = getsockname(isa(client.sock, MbedTLS.SSLContext) ? client.sock.bio : client.sock)
    task_local_storage(:ip, ip)
  catch ex
    Genie.Logger.log("Failed getting IP address of request", :err)
    Genie.Logger.log(string(ex), :err)
    Genie.Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    task_local_storage(:ip, ip"255.255.255.255")
  end

  nothing
 end


"""
    handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response

HttpServer handler function - invoked when the server gets a request.
"""
function handle_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = ip"0.0.0.0") :: HTTP.Response
  Genie.config.log_requests && log_request(req)
  Genie.config.server_signature != "" && sign_response!(res)

  app_response::HTTP.Response = set_headers!(req, res, Genie.Router.route_request(req, res, ip))

  Genie.config.log_responses && log_response(req, app_response)

  app_response
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

HttpServer handler function - invoked when the server gets a request.
"""
function handle_ws_request(req::HTTP.Request, msg::String, ws_client::WebSockets.WebSocket, ip::IPv4 = ip"0.0.0.0") :: String
  Genie.config.log_requests && log_request(req)
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


"""
    log_request(req::Request) :: Nothing

Logs information about the request.
"""
function log_request(req::HTTP.Request) :: Nothing
  if Genie.Router.is_static_file(req.target)
    Genie.config.log_resources && log_request_response(req)
  elseif Genie.config.log_responses
    log_request_response(req)
  end

  nothing
end


"""
    log_response(req::Request, res::Response) :: Nothing

Logs information about the response.
"""
function log_response(req::HTTP.Request, res::HTTP.Response) :: Nothing
  if Genie.Router.is_static_file(req.target)
    Genie.config.log_resources && log_request_response(res)
  elseif Genie.config.log_responses
    log_request_response(res)
  end

  nothing
end


"""
    log_request_response(req_res::Union{Request,Response}) :: Nothing

Helper function that logs `Request` or `Response` objects.
"""
function log_request_response(req_res::Union{HTTP.Request,HTTP.Response}) :: Nothing
  req_data = Dict{String,String}()
  response_is_error = false

  for f in fieldnames(req_res)
    try
      f = string(f)
      v = getfield(req_res, Symbol(f))

      f == "status" && (req_res.status == 404 || req_res.status == 500) && (response_is_error = true)

      req_data[f] = if f == "data" && ! isempty(v)
                      mapreduce(x -> string(Char(Int(x))), *, v) |> Genie.Logger.truncate_logged_output
                    elseif isa(v, Dict) && Genie.config.log_formatted
                      Millboard.table(parse_inner_dict(v)) |> string
                    else
                      string(v) |> Genie.Logger.truncate_logged_output
                    end
    catch ex
      Genie.Logger.log(ex, :err)
    end
  end

  Genie.Logger.log(Dict(req_res.headers))
  Genie.Logger.log(string(req_res) * "\n" * string(Genie.config.log_formatted ? Millboard.table(req_data) : req_data), response_is_error ? :err : :debug, showst = false)

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
    if k == "Cookie" && Genie.config.log_verbosity == Genie.Configuration.LOG_LEVEL_VERBOSITY_VERBOSE
      cookie = Dict{String,String}()
      cookies = split(v, ";")
      for c in cookies
        cookie_part = split(c, "=")
        cookie[cookie_part[1]] = cookie_part[2] |> Genie.Logger.truncate_logged_output
      end

      r[k] = (Genie.config.log_formatted ? Millboard.table(cookie) : cookie) |> string
    else
      r[k] = Genie.Logger.truncate_logged_output(string(v))
    end
  end

  r
end

end
