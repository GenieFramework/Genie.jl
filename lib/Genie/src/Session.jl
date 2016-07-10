module Session

using Genie
using SHA
using HttpServer

const session_data = Dict{Symbol,Any}()

function new_id()
  Genie.SECRET_TOKEN * ":" * sha1(string(Dates.now())) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256
end

function id(req::Request, res::Response)
  if haskey(res.cookies, Genie.config.session_key_name)
    return res.cookies[Genie.config.session_key_name]
  end

  if haskey(req.headers, "Cookie")
    cookies = cookies_dict(req)
    haskey(cookies, Genie.config.session_key_name) && return cookies[Genie.config.session_key_name]
  end

  new_id()
end

function start(req::Request, res::Response)
  setcookie!(res, Genie.config.session_key_name, id(req, res), Dict("Path" => "/", "HttpOnly" => "", "Expires" => "0"))
end

function set(key::Symbol, value::Any)
  session_data[key] = value
end

function get()
  session_data
end

function get(key::Symbol)
  return  if haskey(session_data, key)
            Nullable(session_data[key])
          else
            Nullable()
          end
end

function get!!(key::Symbol)
  session_data[key]
end

function cookies_dict(req::Request)
  d = Dict{AbstractString,AbstractString}()
  for cookie in split(req.headers["Cookie"], ";")
    cookie_parts = split(cookie, "=")
    d[strip(cookie_parts[1])] = cookie_parts[2]
  end

  d
end

end