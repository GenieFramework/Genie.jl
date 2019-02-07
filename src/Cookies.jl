"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

using HTTP, Nullables
using Genie, Genie.Encryption


"""
    get(res::HTTP.Response, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Respose` object.
"""
function get(res::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Nullable{String}
  if haskey(Dict(res.headers), "Set-Cookie")
    cookies = to_dict(res)
    if haskey(cookies, string(key))
      value = cookies[string(key)]
      encrypted && (value = Genie.Encryption.decrypt(value))

      return Nullable{String}(value)
    end
  end

  Nullable{String}()
end


"""
"""
function get!!(res::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: String
  get(res, key, encrypted = encrypted) |> Nullables.get
end


"""
    get(req::Request, key::Union{String,Symbol}) :: Nullable{String}

Retrieves a value stored on the cookie as `key` from the `Request` object.
"""
function get(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Nullable{String}
  if haskey(Dict(req.headers), "Cookie")
    cookies = to_dict(req)
    if haskey(cookies, string(key))
      value = cookies[string(key)]
      encrypted && (value = Genie.Encryption.decrypt(value))

      return Nullable{String}(value)
    end
  end

  Nullable{String}()
end


"""
"""
function get!!(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: String
  get(req, key, encrypted = encrypted) |> Nullables.get
end


"""
"""
function getcookies(req::HTTP.Request) :: Vector{HTTP.Cookies.Cookie}
  HTTP.Cookies.cookies(req)
end
function getcookies(req::HTTP.Request, matching::String) :: Vector{HTTP.Cookies.Cookie}
  HTTP.Cookies.readcookies(req.headers, matching)
end


"""
    set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Response

Sets `value` under the `key` label on the `Cookie`.
"""
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict = Dict(); encrypted = true) :: HTTP.Response
  normalized_attrs = Dict{Symbol,Any}()
  for (k,v) in attributes
    normalized_attrs[Symbol(lowercase(string(k)))] = v
  end

  value = string(value)
  encrypted && (value = Genie.Encryption.encrypt(value))
  cookie = HTTP.Cookies.Cookie(string(key), value; normalized_attrs...)

  headers = Dict(res.headers)
  if haskey(headers, "Set-Cookie")
    headers["Set-Cookie"] *= HTTP.Cookies.String(cookie, false)
  else
    headers["Set-Cookie"] = HTTP.Cookies.String(cookie, false)
  end
  res.headers = [(k => v) for (k,v) in headers]

  res
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
