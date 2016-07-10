module Cookies

using HttpServer
using Genie

function get(res::Response, key::Union{AbstractString,Symbol})
  key = string(key)
  if haskey(res.cookies, Genie.config.session_key_name)
    return Nullable{AbstractString}(res.cookies[Genie.config.session_key_name].value)
  end

  Nullable{AbstractString}()
end

function get(req::Request, key::Union{AbstractString,Symbol})
  key = string(key)
  if haskey(req.headers, "Cookie")
    cookies = to_dict(req)
    if haskey(cookies, key)
      return Nullable{AbstractString}(cookies[Genie.config.session_key_name])
    end
  end

  Nullable{AbstractString}()
end

function set!(res::Response, key::Union{AbstractString,Symbol}, value::Any, attributes::Dict)
  setcookie!(res, string(key), string(value), attributes)
end
function set!(res::Response, key::Union{AbstractString,Symbol}, value::Any)
  set!(res, key, value, Dict())
end

function to_dict(req::Request)
  d = Dict{AbstractString,AbstractString}()
  for cookie in split(req.headers["Cookie"], ";")
    cookie_parts = split(cookie, "=")
    d[strip(cookie_parts[1])] = cookie_parts[2]
  end

  d
end

end