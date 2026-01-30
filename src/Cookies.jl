"""
Functionality for dealing with HTTP cookies.
"""
module Cookies

import HTTP, Dates
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

Retrieves a value stored on the cookie as `key` from the `Response` object's Set-Cookie headers.

# Arguments
- `res::HTTP.Response`: the response object containing the Set-Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted (default: `true`)
"""
function get(res::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  nullablevalue(res, key, encrypted = encrypted)
end


"""
    get(req::HTTP.Request, key::Union{String,Symbol}) :: Union{Nothing,String}

Retrieves a value stored on the cookie as `key` from the `Request` object's Cookie headers.

# Arguments
- `req::HTTP.Request`: the request object containing the Cookie headers
- `key::Union{String,Symbol}`: the name of the cookie value
- `encrypted::Bool`: if `true` the value stored on the cookie is automatically decrypted (default: `true`)
"""
function get(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  nullablevalue(req, key, encrypted = encrypted)
end


"""
    load_cookie_settings!()

Called during Genie startup. Takes the raw user configuration from `Genie.config.cookie_defaults`
(which typically uses String keys) and converts it into an optimized `Dict{Symbol,Any}` 
with normalized keys and processed values (e.g. SameSite enums).

Validates all attributes strictly - throws error if config contains invalid values.
Automatically parses String to Int64 for numeric fields and String to Bool for boolean fields.
This pre-processes the config once at startup to avoid repeated normalization on every cookie creation.

# Validation Rules
- samesite: must be "lax", "strict", or "none" (case-insensitive) → throws on invalid
- max_age: numeric or parseable String → throws only if parse fails
- secure: Bool or parseable String ("true"/"false") → throws only if parse fails
- httponly: Bool or parseable String ("true"/"false") → throws only if parse fails
- path: must be String → throws on invalid
- domain: must be String → throws on invalid
- expires: must be String → throws on invalid

# Raises
- ArgumentError: if any attribute has an invalid type or value that cannot be parsed
"""
function load_cookie_settings!()
  cfg = Genie.config
  
  if !hasfield(typeof(cfg), :cookie_defaults) || cfg.cookie_defaults === nothing
    return
  end

  optimized_defaults = Dict{Symbol,Any}()
  errors = String[]

  for (k, v) in cfg.cookie_defaults
    # Normalize key to Symbol
    key_sym = _normalize_attribute_name(string(k))
    
    # Validate and process each attribute
    val_processed = v
    err_count_before = length(errors)
    
    if key_sym === :samesite
      if isa(v, AbstractString)
        mode = _samesite_to_mode(v)
        if mode === nothing
          push!(errors, "samesite: \"$v\" is invalid. Valid values: \"lax\", \"strict\", \"none\"")
        else
          val_processed = mode
        end
      elseif isa(v, HTTP.Cookies.SameSite)
        val_processed = v # already processed mode
      else
        push!(errors, "samesite: expected String, got $(typeof(v))")
      end
    elseif key_sym === :maxage
      try
        max_age_val, is_logout, logout_expires = _normalize_maxage(v)
        
        if is_logout
          # Logout pattern detected: max_age=0
          # We don't store expires in defaults, it's set in set!() time
        else
          val_processed = max_age_val
        end
      catch e
        push!(errors, "max_age: $(string(e))")
      end
    elseif key_sym === :secure
      try
        val_processed = _normalize_secure(v)
      catch e
        push!(errors, "secure: $(string(e))")
      end
    elseif key_sym === :httponly
      try
        val_processed = _normalize_httponly(v)
      catch e
        push!(errors, "httponly: $(string(e))")
      end
    elseif key_sym === :path
      if !isa(v, AbstractString)
        push!(errors, "path: expected String, got $(typeof(v))")
      elseif !startswith(string(v), "/")
        push!(errors, "path: \"$v\" should start with \"/\"")
      end
    elseif key_sym === :domain
      try
        val_processed = _normalize_domain(v)
      catch e
        push!(errors, "domain: $(string(e))")
      end
    elseif key_sym === :expires
      if !isa(v, AbstractString) && !isa(v, Dates.DateTime)
        push!(errors, "expires: expected String or DateTime, got $(typeof(v))")
      end
    else
      push!(errors, "unknown attribute: \"$k\" is not a recognized cookie attribute")
    end

    # Only add if no errors for this attribute
    if length(errors) == err_count_before
      optimized_defaults[key_sym] = val_processed
    end
  end

  # Throw all errors together for clarity
  if !isempty(errors)
    error_msg = "Invalid cookie configuration:\n" * join(["  - " * e for e in errors], "\n")
    throw(ArgumentError(error_msg))
  end

  # Replace raw config with optimized version
  cfg.cookie_defaults = optimized_defaults
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
- Config-defined defaults are applied if available and user doesn't override

# See Also
- [`get`](@ref) - Retrieve cookie values from requests
- [`Genie.Encryption.encrypt`](@ref) - Encryption function used for encrypted cookies
"""
function set!(res::HTTP.Response, key::Union{String,Symbol}, value::Any, attributes::Dict{String,<:Any} = Dict{String,Any}(); encrypted::Bool = true) :: HTTP.Response
  r = Genie.Headers.normalize_headers(res)
  
  # ========== LOAD DEFAULTS ==========
  # Start with pre-optimized config defaults (processed at startup by load_cookie_settings!())
  # These are already normalized Symbol keys and validated values, avoiding repeated parsing
  defaults = Genie.config.cookie_defaults
  cookie_attrs = defaults === nothing ? Dict{Symbol,Any}() : copy(defaults)
  
  # ========== PROCESS USER ATTRIBUTES ==========
  # User-provided attributes override config defaults
  # Each attribute is normalized and validated using type-specific helpers
  for (k,v) in attributes
    attr_key = _normalize_attribute_name(k)
    
    if attr_key === :samesite && isa(v, AbstractString)
      # Convert SameSite string to HTTP.Cookies mode enum
      mode = _samesite_to_mode(v)
      if mode !== nothing
        cookie_attrs[attr_key] = mode
      else
        @warn "Unknown SameSite mode: $v. Valid modes: lax, strict, none"
      end
    elseif attr_key === :maxage
      # Normalize max_age integer and detect logout pattern (max_age=0)
      # Logout pattern converts max_age=0 to expires=epoch for browser cookie deletion
      max_age_val, is_logout, logout_expires = _normalize_maxage(v)
      
      if is_logout
        # Logout pattern: set expires to Unix epoch for browser invalidation
        if logout_expires !== nothing
          cookie_attrs[:expires] = logout_expires
        end
      else
        cookie_attrs[attr_key] = max_age_val
      end
    elseif attr_key === :expires
      # Normalize expires value: convert string formats to DateTime
      # Regex-based format detection (RFC 2822, ISO 8601, Unix timestamp)
      normalized = _normalize_expires(v)
      cookie_attrs[attr_key] = normalized
    elseif attr_key === :domain
      # Normalize and validate domain format at runtime
      # Ensures domain is properly formatted and lowercase
      try
        cookie_attrs[attr_key] = _normalize_domain(v)
      catch e
        throw(ArgumentError("domain: $(e.msg)"))
      end
    else
      # Pass through other attributes unchanged (path, secure, httponly, etc.)
      cookie_attrs[attr_key] = v
    end
  end

  # ========== RFC 6265bis COMPLIANCE ==========
  # SameSite=None requires Secure flag for browser acceptance
  # This ensures CSRF protection works correctly with cross-site requests
  if Base.get(cookie_attrs, :samesite, nothing) == HTTP.Cookies.SameSiteNoneMode
    if !Base.get(cookie_attrs, :secure, false)
      cookie_attrs[:secure] = true
      Genie.Configuration.isprod() || @warn "Cookie '$key' with SameSite=None requires Secure=true. Adjusted automatically."
    end
  end

  value = string(value)
  encrypted && (value = Genie.Encryption.encrypt(value))
  
  cookie = HTTP.Cookies.Cookie(string(key), value; cookie_attrs...)
  HTTP.Cookies.addcookie!(r, cookie)

  r
end


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

@static if VERSION >= v"1.9"
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
function nullablevalue(cookie_header::AbstractString, key::String; encrypted::Bool = true) :: Union{Nothing,String}  
  key_lower = lowercase(key)
  
  # Iterate through cookie pairs separated by semicolons
  # Using _split_cookies (eachsplit for v1.9+) for memory efficiency - returns views, not copies
  for cookie in _split_cookies(cookie_header, ';')
    cookie = strip(cookie)
    idx = findfirst('=', cookie)
    
    # ========== PARSE COOKIE NAME ==========
    # Strategy: Work with SubString views to avoid allocations
    # Only convert to String when we have the final result
    # This reduces GC pressure in high-traffic scenarios
    
    # Extract cookie name as a view
    # - If '=' exists: cookie[1:idx-1] is a SubString view (no allocation)
    # - If no '=': use entire cookie as name
    # strip() on SubString returns another SubString (no allocation)
    cookie_name_view = if idx !== nothing
      strip(cookie[1:idx-1])  # SubString view, no memory allocation
    else
      strip(cookie)  # SubString view
    end
    
    # ========== MATCH COOKIE NAME ==========
    # Case-insensitive comparison: lowercase the name view for matching
    # Note: lowercase() on SubString returns a new String (unavoidable for comparison)
    # This is acceptable because we only allocate when name matches
    if lowercase(cookie_name_view) == key_lower
      
      # ========== PARSE COOKIE VALUE ==========
      # Extract value between '=' and end of string
      # Strategy: Work with SubString views to defer allocation until final conversion
      # - Remove surrounding quotes: strip(..., '"')  
      # - Remove leading/trailing whitespace: strip()
      # - Convert to String only when needed (for size validation & encryption)
      value = if idx !== nothing
        # Strip quotes first, then whitespace: handles cases like ` " value " `
        # Pipe to string() defers allocation until we have the final value
        strip(strip(cookie[idx+1:end], '"')) |> string
      else
        # No '=' means cookie has no value, return empty string
        ""
      end
      
      # ========== VALIDATE SIZE ==========
      # Size limit validation (if configured)
      # Reject oversized cookies to prevent memory exhaustion attacks
      if Genie.config.max_cookie_size !== nothing && length(value) > Genie.config.max_cookie_size
        @debug "Cookie value exceeds maximum size of $(Genie.config.max_cookie_size) bytes"
        return nothing
      end
      
      # ========== DECRYPT (IF NEEDED) ==========
      # Genie.Encryption.decrypt() expects String input and returns String
      # This is safe because value is already a String at this point
      encrypted && (value = Genie.Encryption.decrypt(value))
      
      # ========== RETURN ==========
      # At this point, value is guaranteed to be a String
      # Type signature: Union{Nothing,String} is satisfied ✓
      return value
    end
  end

  # No matching cookie found anywhere in the header
  # Return nothing (second part of Union{Nothing,String})
  nothing
end
nullablevalue(cookie_header::AbstractString, key::Symbol; encrypted::Bool = true) :: Union{Nothing,String} =
  nullablevalue(cookie_header, string(key); encrypted = encrypted)

function nullablevalue(payload::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  # ========== DISPATCHER FOR HTTP.REQUEST ==========
  # Iterate through request headers to find "Cookie" header
  # Note: value from payload.headers is a SubString view (no allocation)
  # Delegate to core string-based nullablevalue() for efficient parsing
  for (name, value) in payload.headers
    if lowercase(name) == "cookie"
      val = nullablevalue(value, key; encrypted = encrypted)
      if val !== nothing
        return val
      end
    end
  end
  nothing
end
function nullablevalue(payload::HTTP.Response, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  # ========== DISPATCHER FOR HTTP.RESPONSE ==========
  # Iterate through response headers to find "Set-Cookie" header
  # Note: value from payload.headers is a SubString view (no allocation)
  # Delegate to core string-based nullablevalue() for efficient parsing
  for (name, value) in payload.headers
    if lowercase(name) == "set-cookie"
      val = nullablevalue(value, key; encrypted = encrypted)
      if val !== nothing
        return val
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


"""
    _normalize_attribute_name(name::AbstractString)

Normalizes the attribute name to standard lowercase symbols, handling legacy variations 
like "Max-Age" -> :maxage or "HttpOnly" -> :httponly.
"""
function _normalize_attribute_name(name::String) :: Symbol
    n = lowercase(name)
    n == "path" && return :path
    n == "secure" && return :secure
    n == "httponly" && return :httponly
    n == "domain" && return :domain
    n == "expires" && return :expires
    n == "maxage" && return :maxage
    n == "samesite" && return :samesite
    n == "max-age" && return :maxage
    n == "http-only" && return :httponly
    n == "same-site" && return :samesite
    n == "same_site" && return :samesite
    n == "max_age" && return :maxage
    n == "http_only" && return :httponly
    
    return n |> Symbol
end

"""Helper to convert SameSite string to mode object

Converts string representations of SameSite modes ("lax", "strict", "none") to their 
corresponding HTTP.Cookies.SameSite enum values. Case-insensitive.

# Arguments
- `val::String`: the SameSite mode as a string

# Returns
- `HTTP.Cookies.SameSite` mode if valid, or `nothing` if unrecognized
"""
function _samesite_to_mode(val::String) :: Union{HTTP.Cookies.SameSite, Nothing}
  val_lower = lowercase(val)
  val_lower == "lax" && return HTTP.Cookies.SameSiteLaxMode
  val_lower == "strict" && return HTTP.Cookies.SameSiteStrictMode
  val_lower == "none" && return HTTP.Cookies.SameSiteNoneMode
  nothing
end

"""Helper to normalize expires value from string to DateTime

Uses regex format detection (not exception-based control flow) for better performance.
Logs when parsing fails so operators can spot misconfigured expires values.
"""
function _normalize_expires(val::Any) :: Union{Dates.DateTime, Any}
  if !isa(val, AbstractString)
    return val  # Return as-is if not a string (already DateTime, etc)
  end
  
  # Detect format using regex before attempting parse (faster than try-catch exception flow)
  
  # Try RFC 2822 format: "Wed, 09 Jun 2025 10:18:14 GMT"
  if occursin(r"^[A-Za-z]{3},\s+\d{2}\s+[A-Za-z]{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+[A-Z]{3}$", val)
    try
      return Dates.DateTime(val, "e, dd u yyyy HH:MM:SS Z")
    catch e
      @debug "Failed to parse RFC 2822 expires format" value=val error=string(e)
    end
  end
  
  # Try ISO 8601 format: "2025-06-09T10:18:14Z"
  if occursin(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$", val)
    try
      return Dates.DateTime(val, "yyyy-mm-ddTHH:MM:SSZ")
    catch e
      @debug "Failed to parse ISO 8601 expires format" value=val error=string(e)
    end
  end
  
  # Try Unix timestamp (numeric string)
  if occursin(r"^\d+$", val)
    try
      ts = parse(Int64, val)
      return Dates.unix2datetime(ts)
    catch e
      @debug "Failed to parse Unix timestamp expires format" value=val error=string(e)
    end
  end
  
  # If no format matches, log and return original value for HTTP.Cookies to handle
  @debug "Unrecognized expires format; returning original value" value=val
  val
end

"""Helper to normalize domain strings and validate format.
Throws ArgumentError on invalid input."""
function _normalize_domain(val::Any) :: String
  if !isa(val, AbstractString)
    throw(ArgumentError("domain: expected String, got $(typeof(val))"))
  end

  d = strip(String(val))
  if isempty(d)
    throw(ArgumentError("domain: cannot be empty"))
  end

  # Allow leading dot for site-wide cookies, then validate characters
  # Valid characters: letters, digits, hyphen, dot
  if !occursin(r"^[A-Za-z0-9\.-]+$", d)
    throw(ArgumentError("domain: contains invalid characters: \"$val\""))
  end

  return lowercase(d)
end

"""Helper to normalize secure boolean value from various inputs.
Accepts Bool, or String ("true"/"false"/"1"/"0"/"yes"/"no"). Returns Bool."""
function _normalize_secure(val::Any) :: Bool
  if isa(val, Bool)
    return val
  elseif isa(val, AbstractString)
    val_str = lowercase(string(val))
    if val_str in ("true", "1", "yes")
      return true
    elseif val_str in ("false", "0", "no")
      return false
    else
      throw(ArgumentError("secure: cannot parse '$val' to Bool (use true/false/1/0/yes/no)"))
    end
  else
    throw(ArgumentError("secure: expected Bool or String, got $(typeof(val))"))
  end
end

"""Helper to normalize httponly boolean value from various inputs.
Accepts Bool, or String ("true"/"false"/"1"/"0"/"yes"/"no"). Returns Bool."""
function _normalize_httponly(val::Any) :: Bool
  if isa(val, Bool)
    return val
  elseif isa(val, AbstractString)
    val_str = lowercase(string(val))
    if val_str in ("true", "1", "yes")
      return true
    elseif val_str in ("false", "0", "no")
      return false
    else
      throw(ArgumentError("httponly: cannot parse '$val' to Bool (use true/false/1/0/yes/no)"))
    end
  else
    throw(ArgumentError("httponly: expected Bool or String, got $(typeof(val))"))
  end
end

"""Helper to normalize secure boolean value from various inputs.
Accepts Bool, or String ("true"/"false"/"1"/"0"/"yes"/"no"). Returns Bool."""
function _normalize_maxage(val::Any) :: Tuple{Union{Int64, Nothing}, Bool, Union{Dates.DateTime, Nothing}}
  # Convert to Int64
  max_age_val = if isa(val, AbstractString)
    try
      Int64(parse(Int, val))
    catch
      throw(ArgumentError("max_age: cannot parse '$val' as integer"))
    end
  elseif isa(val, Int64)
    val
  else
    try
      Int64(val)
    catch
      throw(ArgumentError("max_age: expected Int64 or String, got $(typeof(val))"))
    end
  end
  
  # LOGOUT PATTERN: max_age=0 means delete the cookie
  # Convert to expires in the past (Unix epoch 1970) for browser recognition
  if max_age_val == 0
    expires_dt = try
      Dates.DateTime("1970-01-01T00:00:00")
    catch
      nothing
    end
    return (nothing, true, expires_dt)  # (max_age=nothing, is_logout=true, expires_datetime)
  else
    return (max_age_val, false, nothing)  # (max_age_value, is_logout=false, expires_datetime=nothing)
  end
end


end
