module AppServer

using HttpServer, Router, Genie, Millboard, Logger, Sessions, Configuration

function startup(port::Int = 8000)
  http = HttpHandler() do req::Request, res::Response
    try
      nworkers() == 1 ? handle_request(req, res) : @fetch handle_request(req, res)
    catch ex
      Logger.log("Genie error " * string(ex), :critical, showst = false)
      Router.serve_error_file(500, string(ex))
    end
  end

  server = Server(http)
  run(server, port)
end

function handle_request(req::Request, res::Response)
  log_request(req)
  sign_response!(res)

  app_response::Response = Router.route_request(req, res)
  app_response.headers = merge(res.headers, app_response.headers)
  app_response.cookies = merge(res.cookies, app_response.cookies)

  AppServer.log_response(req, app_response)

  app_response
end

function sign_response!(res::Response)
  res.headers["Server"] = Genie.config.server_signature
  res
end

function log_request(req::Request)
  if Router.is_static_file(req.resource)
    Genie.config.log_resources && log_request_response(req)
  elseif Genie.config.log_responses
    log_request_response(req)
  end
end

function log_response(req::Request, res::Response)
  if Router.is_static_file(req.resource)
    Genie.config.log_resources && log_request_response(res)
  elseif Genie.config.log_responses
    log_request_response(res)
  end
end

function log_request_response(req_res::Union{Request,Response})
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
end

function parse_inner_dict(d::Dict)
  r = Dict()
  for (k, v) in d
    if k == "Cookie" && Genie.config.log_verbosity == Configuration.LOG_LEVEL_VERBOSITY_VERBOSE
      cookie = Dict()
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