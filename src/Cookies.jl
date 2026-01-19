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

Retrieves a value stored on the cookie as `key` from the `Response` object.

# Arguments
- `res::HTTP.Response`: the response object containing the Set-Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function get(res::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  nullablevalue(res, key, encrypted = encrypted)
end


"""
    get(req::HTTP.Request, key::Union{String,Symbol}) :: Union{Nothing,String}

Retrieves a value stored on the cookie as `key` from the `Request` object.

# Arguments
- `req::HTTP.Request`: the request object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted
"""
function get(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  nullablevalue(req, key, encrypted = encrypted)
end


"""
    set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict; encrypted::Bool = true) :: HTTP.Response

Sets a cookie on an `HTTP.Response` object with the specified `key` and `value`.

The cookie value is automatically converted to a string and can be encrypted for security.
Additional cookie attributes (path, domain, max-age, etc.) can be specified.

# Arguments
- `res::HTTP.Response`: the HTTP.Response object to add the cookie to
- `key::Union{String,Symbol}`: the name of the cookie
- `value::Any`: the cookie value (will be converted to string)
- `attributes::Dict`: optional cookie attributes as key-value pairs, e.g. `Dict("path" => "/", "httponly" => true)`
- `encrypted::Bool`: if `true`, the value is encrypted before storing (default: `true`)

# Cookie Attributes
Common attributes that can be set:
- `path`: path restriction for the cookie (default: "/")
- `domain`: domain restriction for the cookie
- `max_age`: cookie lifetime in seconds
- `expires`: expiration date
- `secure`: only send over HTTPS (set to `true` or omit)
- `httponly`: prevent JavaScript access (set to `true` or omit)
- `samesite`: CSRF protection mode (`:lax`, `:none`, or `:strict`)

# SameSite Modes
- `"lax"` or `"Lax"` → `HTTP.Cookies.SameSiteLaxMode`
- `"strict"` or `"Strict"` → `HTTP.Cookies.SameSiteLaxStrict`
- `"none"` or `"None"` → `HTTP.Cookies.SameSiteLaxNone`

# Returns
- Modified `HTTP.Response` with the cookie added

# Examples
```julia
# Simple encrypted cookie
res = HTTP.Response(200)
res = Genie.Cookies.set!(res, "user_id", "12345", encrypted=true)

# With attributes
attrs = Dict("path" => "/", "max_age" => 3600, "httponly" => true)
res = Genie.Cookies.set!(res, "session", "abc123xyz", attrs, encrypted=true)

# Non-encrypted cookie with SameSite
attrs = Dict("samesite" => "lax", "secure" => true)
res = Genie.Cookies.set!(res, "preference", "dark_mode", attrs, encrypted=false)
```

# Notes
- Attribute names are case-insensitive (automatically lowercased)
- If `encrypted=true`, the value is encrypted using `Genie.Encryption.encrypt()`
- The function modifies and returns the response object
- Returns are chainable for multiple cookie operations

# See Also
- [`get`](@ref) - Retrieve cookie values from requests
- [`Genie.Encryption.encrypt`](@ref) - Encryption function used for encrypted cookies
"""
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict{String,<:Any} = Dict{String,Any}(); encrypted::Bool = true) :: HTTP.Response
  r = Genie.Headers.normalize_headers(res)
  cookie_attrs = Dict{Symbol,Any}()
  
  for (k,v) in attributes
    attr_key = normalize_attribute_name(k) |> Symbol
    attr_val = v
    
    # Handle SameSite mode conversion
    if attr_key === :samesite
      samesite_mode = lowercase(string(v))
      samesite_map = Dict(
        "lax"    => HTTP.Cookies.SameSiteLaxMode,
        "strict" => HTTP.Cookies.SameSiteStrictMode,
        "none"   => HTTP.Cookies.SameSiteNoneMode
      )
      
      if haskey(samesite_map, samesite_mode)
        attr_val = samesite_map[samesite_mode]
      else
        @warn "Unknown SameSite mode: $v. Valid modes: lax, strict, none"
      end
    end
    
    cookie_attrs[attr_key] = attr_val
  end

  value = string(value)
  encrypted && (value = Genie.Encryption.encrypt(value))
  
  cookie = HTTP.Cookies.Cookie(string(key), value; cookie_attrs...)
  HTTP.Cookies.addcookie!(r, cookie)

  r
end

"""
    normalize_attribute_name(attr_name::String) :: String

Normalizes cookie attribute names by:
1. Converting to lowercase for consistency
2. Converting underscored versions to their native forms

Conversions:
- "max_age", "MAX_AGE", "Max_Age", etc. → "maxage"
- "http_only", "HTTP_ONLY", "Http_Only", etc. → "httponly"  
- "same_site", "SAME_SITE", "Same_Site", etc. → "samesite"

Returns the normalized attribute name and emits a warning if normalization occurred.
"""
function normalize_attribute_name(attr_name::String) :: String
  attr_name = lowercase(attr_name)
  
  if occursin("max_age", attr_name)
    attr_name = replace(attr_name, "max_age" => "maxage")
    @warn "Normalized cookie attribute \"max_age\" to \"maxage\". " *
          "Both forms are supported, but the normalized form is recommended."
  elseif occursin("http_only", attr_name)
    attr_name = replace(attr_name, "http_only" => "httponly")
    @warn "Normalized cookie attribute \"http_only\" to \"httponly\". " *
          "Both forms are supported, but the normalized form is recommended."
  elseif occursin("same_site", attr_name)
    attr_name = replace(attr_name, "same_site" => "samesite")
    @warn "Normalized cookie attribute \"same_site\" to \"samesite\". " *
          "Both forms are supported, but the normalized form is recommended."
  end
  
  attr_name
end
normalize_attribute_name(attr_name::Symbol) :: String =
  normalize_attribute_name(string(attr_name))


"""
    Dict(r::Union{HTTP.Request,HTTP.Response}) :: Dict{String,String}

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

@static if VERSION >= v"1.7"
    const _split_cookies = eachsplit
else
    const _split_cookies = split
end

"""
    nullablevalue(payload::Union{HTTP.Response,HTTP.Request}, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}

Attempts to retrieve a cookie value stored at `key` in the `payload` object and returns a `Union{Nothing,String}`.

This is the core function for cookie retrieval that handles:
- Cookie parsing from request/response headers
- Cookie value decryption (if enabled)
- Cookie size validation (if configured)

# Arguments
- `payload::Union{HTTP.Response,HTTP.Request}`: the request or response object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie to retrieve
- `encrypted::Bool`: if `true`, the cookie value is automatically decrypted (default: `true`)

# Returns
- `Nothing` if the cookie is not found, invalid, or exceeds size limit
- `String` with the cookie value if found and valid

# Configuration
- `Genie.config.max_cookie_size`: Maximum allowed cookie value size in bytes
  - `nothing` (default): No size limit
  - `Integer`: Enforce maximum size limit (e.g., 4096 for 4KB)
"""
function nullablevalue(cookie_header::String, key::String; encrypted::Bool = true) :: Union{Nothing,String}  
  for cookie in _split_cookies(cookie_header, ';')
    cookie = strip(cookie)
    if startswith(lowercase(cookie), lowercase(key))
      idx = findfirst('=', cookie)
      value = idx !== nothing ? string(strip(strip(cookie[idx+1:end], '"'))) : ""
      
      if Genie.config.max_cookie_size !== nothing && length(value) > Genie.config.max_cookie_size
        @debug "Cookie value exceeds maximum size of $(Genie.config.max_cookie_size) bytes"
        return nothing
      end
      
      encrypted && (value = Genie.Encryption.decrypt(value))

      return string(value)
    end
  end

  nothing
end
nullablevalue(cookie_header::String, key::Symbol; encrypted::Bool = true) :: Union{Nothing,String} =
  nullablevalue(cookie_header, string(key); encrypted = encrypted)

function nullablevalue(payload::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  cookie_header = HTTP.header(payload, "Set-Cookie")
  isempty(cookie_header) && return nothing
  nullablevalue(cookie_header |> string, key; encrypted = encrypted)
end
function nullablevalue(payload::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  cookie_header = HTTP.header(payload, "Cookie")
  isempty(cookie_header) && return nothing
  nullablevalue(cookie_header |> string, key; encrypted = encrypted)
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
