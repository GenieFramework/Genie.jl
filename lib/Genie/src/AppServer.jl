module AppServer

using HttpServer
using Router
using Genie
using Millboard

# function start_handlers()
#   nworkers() < Genie.config.server_handlers_count && addprocs(Genie.config.server_handlers_count - nworkers())
# end

function start(port::Int = 8000)
  # start_handlers()

  http = HttpHandler() do req::Request, res::Response
    try
      # @fetch Response(string(Dates.now()) * "-" * string(myid())) # handle_request(req, res)
      handle_request(req, res)
    catch ex
      Genie.log("Genie error " * string(ex), :critical, showst = false)
      Router.serve_error_file(500, string(ex))
    end
  end

  server = Server(http)
  run(server, port)
end

function handle_request(req::HttpServer.Request, res::HttpServer.Response)
  session = Sessions.start(req, res)
  AppServer.log_request(req) # <== here crashes in parallel
  AppServer.sign_response!(res)

  app_response::Response = Router.route_request(req, res, session)
  app_response.headers = merge(res.headers, app_response.headers)
  app_response.cookies = merge(res.cookies, app_response.cookies)

  AppServer.log_response(req, app_response)
  Sessions.persist(session)

  app_response
end

function spawn!(server_workers, port::Int = 8000)
  port_increment = 0

  # for w in 1:Genie.config.server_workers_count
  push!(server_workers, start(port + port_increment))
  port_increment += 1
  # end

  server_workers
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

function log_request_response(req_res::Union{Request, Response})
  req_data = Dict{AbstractString, AbstractString}()
  response_is_error = false

  for f in fieldnames(req_res)
    f = string(f)
    v = getfield(req_res, Symbol(f))

    f == "status" && (req_res.status == 404 || req_res.status == 500) && (response_is_error = true)

    req_data[f] = if f == "data" && ! isempty(v)
                    mapreduce(x -> string(Char(Int(x))), *, v) |> Genie.truncate_logged_output
                  elseif isa(v, Dict) && Genie.config.log_formatted
                    Millboard.table(parse_inner_dict(v)) |> string
                  else
                    string(v) |> Genie.truncate_logged_output
                  end
  end

  Genie.log(string(req_res) * "\n" * string(Genie.config.log_formatted ? Millboard.table(req_data) : req_data), response_is_error ? :err : :debug, showst = false)
end

function parse_inner_dict(d::Dict)
  r = Dict()
  for (k, v) in d
    if k == "Cookie" && Genie.config.log_verbosity == LOG_LEVEL_VERBOSITY_VERBOSE
      cookie = Dict()
      cookies = split(v, ";")
      for c in cookies
        cookie_part = split(c, "=")
        cookie[cookie_part[1]] = cookie_part[2] |> Genie.truncate_logged_output
      end

      r[k] = (Genie.config.log_formatted ? Millboard.table(cookie) : cookie) |> string
    else
      r[k] = Genie.truncate_logged_output(string(v))
    end
  end

  r
end

end