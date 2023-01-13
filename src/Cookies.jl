"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

import HTTP
import Genie, Genie.Encryption, Genie.HTTPUtils


"""
    get(payload::Union{HTTP.Response,HTTP.Request}, key::Union{String,Symbol}, default::T; encrypted::Bool = true)::T where T

Attempts to get the Cookie value stored at `key` within `payload`.
If the `key` is not set, the `default` value is returned.

# Arguments
- `payload::Union{HTTP.Response,HTTP.Request}`: the request or response object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `default::T`: default value to be returned if no cookie value is set at `key`
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function get(payload::Union{HTTP.Response,HTTP.Request}, key::Union{String,Symbol}, default::T; encrypted::Bool = true)::T where T
  val = get(payload, key, encrypted = encrypted)
  val === nothing ? default : parse(T, val)
end


"""
    get(res::HTTP.Response, key::Union{String,Symbol}) :: Union{Nothing,String}

Retrieves a value stored on the cookie as `key` from the `Respose` object.

# Arguments
- `payload::Union{HTTP.Response,HTTP.Request}`: the request or response object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function get(res::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  (haskey(HTTPUtils.Dict(res), "Set-Cookie") || haskey(HTTPUtils.Dict(res), "set-cookie")) ?
    nullablevalue(res, key, encrypted = encrypted) :
      nothing
end


"""
    get(req::Request, key::Union{String,Symbol}) :: Union{Nothing,String}

Retrieves a value stored on the cookie as `key` from the `Request` object.

# Arguments
- `req::HTTP.Request`: the request or response object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function get(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  (haskey(HTTPUtils.Dict(req), "cookie") || haskey(HTTPUtils.Dict(req), "Cookie")) ?
    nullablevalue(req, key, encrypted = encrypted) :
      nothing
end


"""
    set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict; encrypted::Bool = true) :: HTTP.Response

Sets `value` under the `key` label on the `Cookie`.

# Arguments
- `res::HTTP.Response`: the HTTP.Response object
- `key::Union{String,Symbol}`: the key for storing the cookie value
- `value::Any`: the cookie value
- `attributes::Dict`: additional cookie attributes, such as `path`, `httponly`, `maxage`
- `encrypted::Bool`: if `true` the value is stored encoded
"""
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict{String,<:Any} = Dict{String,Any}(); encrypted::Bool = true) :: HTTP.Response
  r = Genie.Headers.normalize_headers(res)
  normalized_attrs = Dict{Symbol,Any}()
  for (k,v) in attributes
    normalized_attrs[Symbol(lowercase(string(k)))] = v
  end

  if haskey(normalized_attrs, :samesite)
    if lowercase(normalized_attrs[:samesite]) == "lax"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteLaxMode
    elseif lowercase(normalized_attrs[:samesite]) == "none"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteLaxNone
    elseif lowercase(normalized_attrs[:samesite]) == "strict"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteLaxStrict
    end
  end

  value = string(value)
  encrypted && (value = Genie.Encryption.encrypt(value))
  cookie = HTTP.Cookies.Cookie(string(key), value; normalized_attrs...)

  HTTP.Cookies.addcookie!(r, cookie)

  r
end


"""
    Dict(req::Request) :: Dict{String,String}

Extracts the `Cookie` and `Set-Cookie` data from the `Request` and `Response` objects and converts it into a Dict.
"""
function Base.Dict(r::Union{HTTP.Request,HTTP.Response}) :: Dict{String,String}
  r = Genie.Headers.normalize_headers(r)
  d = Dict{String,String}()
  headers = Dict(r.headers)

  h = if haskey(headers, "Cookie")
    split(headers["Cookie"], ";")
  elseif haskey(headers, "Set-Cookie")
    split(headers["Set-Cookie"], ";")
  else
    []
  end

  for cookie in h
    cookie_parts = split(cookie, "=")
    if length(cookie_parts) == 2
      d[strip(cookie_parts[1])] = cookie_parts[2]
    else
      d[strip(cookie_parts[1])] = ""
    end
  end

  d
end


### PRIVATE ###


"""
    nullablevalue(payload::Union{HTTP.Response,HTTP.Request}, key::Union{String,Symbol}; encrypted::Bool = true)

Attempts to retrieve a cookie value stored at `key` in the `payload object` and returns a `Union{Nothing,String}`

# Arguments
- `payload::Union{HTTP.Response,HTTP.Request}`: the request or response object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function nullablevalue(payload::Union{HTTP.Response,HTTP.Request}, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  for cookie in split(Dict(payload)["cookie"], ';')
    cookie = strip(cookie)
    if startswith(lowercase(cookie), lowercase(string(key)))
      value = split(cookie, '=')[2] |> String
      encrypted && (value = Genie.Encryption.decrypt(value))

      return string(value)
    end
  end

  nothing
end


"""
    getcookies(req::HTTP.Request) :: Vector{HTTP.Cookies.Cookie}

Extracts cookies from within `req`
"""
function getcookies(req::HTTP.Request) :: Vector{HTTP.Cookies.Cookie}
  HTTP.Cookies.cookies(req)
end


"""
    getcookies(req::HTTP.Request) :: Vector{HTTP.Cookies.Cookie}

Extracts cookies from within `req`, filtering them by `matching` name.
"""
function getcookies(req::HTTP.Request, matching::String) :: Vector{HTTP.Cookies.Cookie}
  HTTP.Cookies.readcookies(req.headers, matching)
end

end
