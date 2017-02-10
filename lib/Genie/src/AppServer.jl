module AppServer

using HttpServer, Router, Genie, Millboard, Logger, Sessions, Configuration, MbedTLS

"""
    startup(port::Int = 8000) :: Void

Starts the web server on the configurated port.
Automatically invoked when Genie is started with the `s` or the `server:start` command line params.
Can be manually invoked from the REPL as well, when starting Genie without the above params -- ideally `async` to allow reusing the REPL session.

# Examples
```julia
julia> @spawn AppServer.startup()
Listening on 0.0.0.0:8000...
Future(1,1,1,Nullable{Any}())
```
"""
function startup(port::Int = 8000) :: Void
  http = HttpHandler() do req::Request, res::Response
    try
      ip::IPv4 = task_local_storage(:ip)
      nworkers() == 1 ? handle_request(req, res, ip) : @fetch handle_request(req, res)
    catch ex
      if Configuration.is_dev()
        rethrow(ex)
      else
        Logger.log("Genie error " * string(ex), :critical, showst = false)
        Logger.@location()

        Router.serve_error_file(500, string(ex))
      end
    end
  end

  http.events["connect"] = (client) -> handle_connect(client)

  server = Server(http)
  @async run(server, port) # !!! @async required to avoid race conditions when storing the request IP ???

  if Genie.config.run_as_server
    while true
      sleep(1_000_000)
    end
  end

  nothing
end


"""
    handle_connect(client::HttpServer.Client) :: Void

Connection callback for HttpServer. Stores the Request IP in the current task's local storage.
"""
function handle_connect(client::HttpServer.Client) :: Void
  try
    ip, port = getsockname(isa(client.sock, MbedTLS.SSLContext) ? client.sock.bio : client.sock)
    task_local_storage(:ip, ip)

     nothing
  catch ex
    string(ex) |> Logger.log
    Logger.@location()
  end
 end


"""
    handle_request(req::Request, res::Response) :: Response

HttpServer handler function - invoked when the server gets a request.
"""
function handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response
  Genie.config.log_requests && log_request(req)
  Genie.config.server_signature != "" && sign_response!(res)

  app_response::Response = Router.route_request(req, res, ip)
  app_response.headers = merge(res.headers, app_response.headers)
  app_response.cookies = merge(res.cookies, app_response.cookies)

  Genie.config.log_responses && log_response(req, app_response)

  app_response
end


"""
    sign_response!(res::Response) :: Response

Adds a signature header to the response using the value in `Genie.config.server_signature`.
If `Genie.config.server_signature` is empty, the header is not added.
"""
function sign_response!(res::Response) :: Response
  if ! isempty(Genie.config.server_signature)
    res.headers["Server"] = Genie.config.server_signature
  end

  res
end


"""
    log_request(req::Request) :: Void

Logs information about the request.
"""
function log_request(req::Request) :: Void
  if Router.is_static_file(req.resource)
    Genie.config.log_resources && log_request_response(req)
  elseif Genie.config.log_responses
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
    Genie.config.log_resources && log_request_response(res)
  elseif Genie.config.log_responses
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
                  elseif isa(v, Dict) && Genie.config.log_formatted
                    Millboard.table(parse_inner_dict(v)) |> string
                  else
                    string(v) |> Logger.truncate_logged_output
                  end
  end

  Logger.log(string(req_res) * "\n" * string(Genie.config.log_formatted ? Millboard.table(req_data) : req_data), response_is_error ? :err : :debug, showst = false)

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
    if k == "Cookie" && Genie.config.log_verbosity == Configuration.LOG_LEVEL_VERBOSITY_VERBOSE
      cookie = Dict{String,String}()
      cookies = split(v, ";")
      for c in cookies
        cookie_part = split(c, "=")
        cookie[cookie_part[1]] = cookie_part[2] |> Logger.truncate_logged_output
      end

      r[k] = (Genie.config.log_formatted ? Millboard.table(cookie) : cookie) |> string
    else
      r[k] = Logger.truncate_logged_output(string(v))
    end
  end

  r
end

end
