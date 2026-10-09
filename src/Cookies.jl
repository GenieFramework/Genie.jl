"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

import HTTP
import Genie, Genie.Encryption


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
  nullablevalue(res, key, encrypted = encrypted)
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
  nullablevalue(req, key, encrypted = encrypted)
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
  normalized_attrs = Dict{Symbol,Any}()
  for (k,v) in attributes
    normalized_attrs[Symbol(lowercase(string(k)))] = v
  end

  if haskey(normalized_attrs, :samesite)
    if lowercase(normalized_attrs[:samesite]) == "lax"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteLaxMode
    elseif lowercase(normalized_attrs[:samesite]) == "none"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteNoneMode
    elseif lowercase(normalized_attrs[:samesite]) == "strict"
      normalized_attrs[:samesite] = HTTP.Cookies.SameSiteStrictMode
    end
  end

  value = string(value)
  encrypted && (value = Genie.Encryption.encrypt(value))
  cookie = HTTP.Cookies.Cookie(string(key), value; normalized_attrs...)

  # Use HTTP.Cookies.addcookie! which correctly handles Set-Cookie header
  HTTP.Cookies.addcookie!(res, cookie)

  res
end


"""
    cookie_header_name(::HTTP.Request) :: String
    cookie_header_name(::HTTP.Response) :: String

The header name carrying cookie data for each kind of payload: `Cookie` for a request
(the browser sends all its cookies combined in a single header), `Set-Cookie` for a
response (the server may send one such header per cookie -- there can be more than one).
"""
cookie_header_name(::HTTP.Request) :: String = "Cookie"
cookie_header_name(::HTTP.Response) :: String = "Set-Cookie"


"""
    Dict(req::Request) :: Dict{String,String}

Extracts the `Cookie` (from a request) or `Set-Cookie` (from a response) data and
converts it into a Dict. A response may carry multiple `Set-Cookie` headers (one per
cookie); all of them are included.
"""
function Base.Dict(r::Union{HTTP.Request,HTTP.Response}) :: Dict{String,String}
  r = Genie.Headers.normalize_headers(r)
  header_name = cookie_header_name(r)
  d = Dict{String,String}()

  for (k,v) in r.headers
    k == header_name || continue

    for cookie in split(v, ';')
      cookie_parts = split(strip(cookie), "=")
      if length(cookie_parts) == 2
        d[strip(cookie_parts[1])] = cookie_parts[2]
      else
        d[strip(cookie_parts[1])] = ""
      end
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
  payload = Genie.Headers.normalize_headers(payload)
  header_name = cookie_header_name(payload)

  for (k,v) in payload.headers
    k == header_name || continue

    for cookie in split(v, ';')
      cookie = strip(cookie)
      if startswith(lowercase(cookie), lowercase(string(key)))
        idx = findfirst('=', cookie)
        value = idx !== nothing ? strip(strip(cookie[idx+1:end], '"')) : ""
        if length(value) > 4096
          @debug "Cookie value too large"
          return nothing
        end
        encrypted && (value = Genie.Encryption.decrypt(value))

        return string(value)
      end
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
