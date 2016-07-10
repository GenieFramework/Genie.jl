module AppServer

using HttpServer
using Router
using Genie
using Sessions
using Millboard

function start(port::Int = 8000)
  http = HttpHandler() do req::Request, res::Response
    http_request = req
    http_response = res

    session = Sessions.start(req, res)
    log_request(req)
    sign_response!(res)

    app_response::Response = Router.route_request(req, res, session)
    app_response.headers = merge(http_response.headers, app_response.headers)
    app_response.cookies = merge(http_response.cookies, app_response.cookies)

    log_response(req, app_response)
    Sessions.persist(session)

    app_response
  end

  server = Server(http)
  run(server, port)
end

function spawn(port::Int = 8000)
  Genie.genie_app.server = Nullable{RemoteRef{Channel{Any}}}(_spawn(port))
  if ! isnull(Genie.genie_app.server)
    push!(Genie.genie_app.server_workers, Genie.genie_app.server |> Base.get)
  end

  Genie.genie_app.server
end
function _spawn(port::Int)
  @spawn start(port)
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
  for f in fieldnames(req_res)
    f = string(f)
    v = getfield(req_res, Symbol(f))

    req_data[f] = if f == "data" && ! isempty(v)
                    mapreduce(x -> string(Char(Int(x))), *, v) |> Genie.truncate_logged_output
                  elseif isa(v, Dict) && Genie.config.log_formatted
                    Millboard.table(parse_inner_dict(v)) |> string
                  else
                    string(v) |> Genie.truncate_logged_output
                  end
  end

  Genie.log(string(req_res) * "\n" * string(Genie.config.log_formatted ? Millboard.table(req_data) : req_data))
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