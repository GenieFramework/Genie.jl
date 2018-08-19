"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

using HTTP, HttpCommon, Nullables
using Genie, Genie.Encryption


"""
    get(res::Response, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Respose` object.
"""
function get(res::HTTP.Response, key::Union{String,Symbol}) :: Nullable{String}
  if haskey(Dict(res.headers), "Set-Cookie")
    cookies = to_dict(res)
    if haskey(cookies, string(key))
      return Nullable{String}(cookies[string(key)] |> Genie.Encryption.decrypt)
    end
  end

  Nullable{String}()
end


"""
    get(req::Request, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Request` object.
"""
function get(req::HTTP.Request, key::Union{String,Symbol}) :: Nullable{String}
  if haskey(Dict(req.headers), "Cookie")
    cookies = to_dict(req)
    if haskey(cookies, string(key))
      return Nullable{String}(cookies[string(key)] |> Genie.Encryption.decrypt)
    end
  end

  Nullable{String}()
end


"""
    set!(res::Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Dict{String,HttpCommon.Cookie}
    set!(res::Response, key::Union{String,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}

Sets `value` under the `key` label on the `Cookie`.
"""
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Vector{HTTP.Cookies.Cookie}
  normalized_attrs = typeof(attributes)()
  for (k,v) in attributes
    normalized_attrs[lowercase(string(k))] = v
  end
  HTTP.Cookie(string(key), string(value) |> Genie.Encryption.encrypt; normalized_attrs...)

  HTTP.Cookies.readsetcookies("", "")
end
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}
  set!(res, key, value, Dict())
end


"""
    to_dict(req::Request) :: Dict{String,String}

Extracts the `Cookie` and `Set-Cookie` data from the `Request` and `Response` objects and converts it into a dict.
"""
function to_dict(r::Union{HTTP.Request,HTTP.Response}) :: Dict{String,String}
  d = Dict{String,String}()
  headers = Dict(r.headers)

  if haskey(headers, "Cookie")
    for cookie in split(headers["Cookie"], ";")
      cookie_parts = split(cookie, "=")
      d[strip(cookie_parts[1])] = cookie_parts[2]
    end
  end

  if haskey(headers, "Set-Cookie")
    for cookie in split(headers["Set-Cookie"], ";")
      cookie_parts = split(cookie, "=")
      d[strip(cookie_parts[1])] = cookie_parts[2]
    end
  end

  d
end

end
