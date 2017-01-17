module Cookies

using HttpServer, HttpCommon, Genie

function get(res::Response, key::Union{String,Symbol}) :: Nullable{String}
  key = string(key)
  if haskey(res.cookies, Genie.config.session_key_name)
    return Nullable{String}(res.cookies[Genie.config.session_key_name].value)
  end

  Nullable{String}()
end

function get(req::Request, key::Union{String,Symbol}) :: Nullable{String}
  key = string(key)
  if haskey(req.headers, "Cookie")
    cookies = to_dict(req)
    if haskey(cookies, key)
      return Nullable{String}(cookies[Genie.config.session_key_name])
    end
  end

  Nullable{String}()
end

function set!(res::Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Dict{String,HttpCommon.Cookie}
  setcookie!(res, string(key), string(value), attributes)

  res.cookies
end
function set!(res::Response, key::Union{AbstractString,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}
  set!(res, key, value, Dict())
end

function to_dict(req::Request) :: Dict{String,String}
  d = Dict{String,String}()
  for cookie in split(req.headers["Cookie"], ";")
    cookie_parts = split(cookie, "=")
    d[strip(cookie_parts[1])] = cookie_parts[2]
  end

  d
end

end
