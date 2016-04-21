module AppServer

using HttpServer
using Router
using Jinnie
using Debug
using Millboard

@debug function start(port::Int = 8000)
  http = HttpHandler() do req::Request, res::Response
    Jinnie.config.debug_requests ? log_request_response(req) : nothing 
    
    Router.route_request(req, res)
  end

  server = Server( http )
  run( server, port )
end

function spawn(port::Int = 8000)
  @spawn start(port)
end

@debug function log_request_response(req_res::Union{Request, Response})
  req_data = Dict{AbstractString, AbstractString}()
  for f in fieldnames(req_res)
    f = string(f)
    v = getfield(req_res, Symbol(f))

    req_data[f] = if f == "data" && ! isempty(v)
                    mapreduce(x -> string(Char(Int(x))), *, v) |> Jinnie.truncate_logged_output
                  elseif isa(v, Dict) 
                    Millboard.table(parse_inner_dict(v)) |> string
                  else 
                    string(v) |> Jinnie.truncate_logged_output
                  end
  end

  Jinnie.log(string(req_res) * "\n" * string(Millboard.table(req_data)))
end

function parse_inner_dict(d::Dict)
  r = Dict()
  for (k, v) in d
    if k == "Cookie" 
      cookie = Dict()
      cookies = split(v, ";")
      for c in cookies
        cookie_part = split(c, "=")
        cookie[cookie_part[1]] = cookie_part[2] |> Jinnie.truncate_logged_output
      end

      r[k] = Millboard.table(cookie) |> string
    else 
      r[k] = Jinnie.truncate_logged_output(v)
    end
  end

  r
end

end