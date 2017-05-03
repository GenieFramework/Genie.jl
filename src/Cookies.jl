"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

using HttpServer, HttpCommon, Genie, Encryption


"""
    get(res::Response, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Respose` object.
"""
function get(res::Response, key::Union{String,Symbol}) :: Nullable{String}
  if haskey(res.cookies, string(key))
    return Nullable{String}(res.cookies[string(key)].value |> Encryption.decrypt)
  end

  Nullable{String}()
end


"""
    get(req::Request, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Request` object.
"""
function get(req::Request, key::Union{String,Symbol}) :: Nullable{String}
  if haskey(req.headers, "Cookie")
    cookies = to_dict(req)
    if haskey(cookies, string(key))
      return Nullable{String}(cookies[string(key)] |> Encryption.decrypt)
    end
  end

  Nullable{String}()
end


"""
    set!(res::Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Dict{String,HttpCommon.Cookie}
    set!(res::Response, key::Union{AbstractString,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}

Sets `value` under the `key` label on the `Cookie`.
"""
function set!(res::Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Dict{String,HttpCommon.Cookie}
  setcookie!(res, string(key), string(value) |> Encryption.encrypt, attributes)

  res.cookies
end
function set!(res::Response, key::Union{AbstractString,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}
  set!(res, key, value, Dict())
end


"""
    to_dict(req::Request) :: Dict{String,String}

Extracts the `Cookie` data from the `Request` and converts it into a dict.
"""
function to_dict(req::Request) :: Dict{String,String}
  d = Dict{String,String}()
  for cookie in split(req.headers["Cookie"], ";")
    cookie_parts = split(cookie, "=")
    d[strip(cookie_parts[1])] = cookie_parts[2]
  end

  d
end

end
