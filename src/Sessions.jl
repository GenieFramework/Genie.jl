module Sessions

import Revise
import SHA, HTTP, Dates, Logging
import Genie, Genie.Cookies, Genie.Generator


"""
    mutable struct Session

Represents a session object
"""
mutable struct Session
  id::String
  data::Dict{Symbol,Any}
end
Session(id::String) = Session(id, Dict{Symbol,Any}())

export Session

const session_adapter_name = string(Genie.config.session_storage) * "SessionAdapter"
const SessionAdapter = include("session_adapters/$session_adapter_name.jl")

using .(SessionAdapter)

struct InvalidSessionIdException <: Exception
  msg::String
end
InvalidSessionIdException() = InvalidSessionIdException("Can't compute session id - please make sure SECRET_TOKEN is defined in config/secrets.jl")


"""
    id() :: String

Generates a new session id.
"""
function id() :: String
  if ! isdefined(Genie, :SECRET_TOKEN)
    @error "Session error"

    if ! Genie.Configuration.isprod()
      @warn "Generating temporary secret token"
      Core.eval(Genie, :(const SECRET_TOKEN = $(Genie.Generator.secret_token())))
    else
      throw(InvalidSessionIdException())
    end
  end

  try
    Genie.SECRET_TOKEN * ":" * bytes2hex(SHA.sha1(string(Dates.now()))) * ":" * string(rand()) * ":" * string(hash(Genie)) |> SHA.sha256 |> bytes2hex
  catch ex
    @error ex
    throw(InvalidSessionIdException())
  end
end


"""
    id(payload::Union{HTTP.Request,HTTP.Response}) :: String

Attempts to retrieve the session id from the provided `payload` object.
If that is not available, a new session id is created.
"""
function id(payload::Union{HTTP.Request,HTTP.Response}) :: String
  (Cookies.get(payload, Genie.config.session_key_name) !== nothing) &&
    ! isempty(Cookies.get(payload, Genie.config.session_key_name)) &&
      return Cookies.get(payload, Genie.config.session_key_name)

  id()
end


"""
    id(req::HTTP.Request, res::HTTP.Response) :: String

Attempts to retrieve the session id from the provided request and response objects.
If that is not available, a new session id is created.
"""
function id(req::HTTP.Request, res::HTTP.Response) :: String
  for r in [req, res]
    (Cookies.get(r, Genie.config.session_key_name) !== nothing) &&
      ! isempty(Cookies.get(r, Genie.config.session_key_name)) &&
        return Cookies.get(r, Genie.config.session_key_name)
  end

  id()
end


"""
    start(session_id::String, req::HTTP.Request, res::HTTP.Response; options = Dict{String,String}()) :: Tuple{Session,HTTP.Response}

Initiates a new HTTP session with the provided `session_id`.

# Arguments
- `session_id::String`: the id of the session object
- `req::HTTP.Request`: the request object
- `res::HTTP.Response`: the response object
- `options::Dict{String,String}`: extra options for setting the session cookie, such as `Path` and `HttpOnly`
"""
function start(session_id::String, req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Tuple{Session,HTTP.Response}
  options = merge(Dict("Path" => "/", "HttpOnly" => true), options)
  Cookies.set!(res, Genie.config.session_key_name, session_id, options)

  load(session_id), res
end


"""
    start(req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Session

Initiates a new default session object, generating a new session id.

# Arguments
- `req::HTTP.Request`: the request object
- `res::HTTP.Response`: the response object
- `options::Dict{String,String}`: extra options for setting the session cookie, such as `Path` and `HttpOnly`
"""
function start(req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Tuple{Session,HTTP.Response}
  start(id(req, res), req, res, options = options)
end


"""
    set!(s::Session, key::Symbol, value::Any) :: Session

Stores `value` as `key` on the `Session` object `s`.
"""
function set!(s::Session, key::Symbol, value::Any) :: Session
  s.data[key] = value

  s
end


"""
    get(s::Session, key::Symbol) :: Union{Nothing,Any}

Returns the value stored on the `Session` object `s` as `key`, wrapped in a `Union{Nothing,Any}`.
"""
function get(s::Session, key::Symbol) :: Union{Nothing,Any}
  haskey(s.data, key) ? (s.data[key]) : nothing
end


"""
    get(s::Session, key::Symbol, default::T) :: T where T

Attempts to retrive the value stored on the `Session` object `s` as `key`.
If the value is not set, it returns the `default`.
"""
function get(s::Session, key::Symbol, default::T) :: T where T
  val = get(s, key)

  val === nothing ? default : val
end


"""
    get!!(s::Session, key::Symbol)

Attempts to read the value stored on the `Session` `s` as `key` - throws an exception if the `key` is not set.
"""
function get!!(s::Session, key::Symbol)
  s.data[key]
end


"""
    unset!(s::Session, key::Symbol) :: Session

Removes the value stored on the `Session` `s` as `key`.
"""
function unset!(s::Session, key::Symbol) :: Session
  delete!(s.data, key)

  s
end


"""
    isset(s::Session, key::Symbol) :: Bool

Checks wheter or not `key` exists on the `Session` `s`.
"""
function isset(s::Union{Session,Nothing}, key::Symbol) :: Bool
  s != nothing && haskey(s.data, key)
end


"""
    persist(s::Session) :: Session

Generic method for persisting session data - delegates to the underlying `SessionAdapter`.
"""
function persist(s::Session) :: Session
  SessionAdapter.write(s)

  s
end


"""
    load(session_id::String) :: Session

Loads session data from persistent storage - delegates to the underlying `SessionAdapter`.
"""
function load(session_id::String) :: Session
  session = SessionAdapter.read(session_id)

  session === nothing ? Session(session_id) : (session)
end


"""
    session(params::Dict{Symbol,Any}) :: Sessions.Session

Returns the `Session` object associated with the current HTTP request.
"""
function session(params::Dict{Symbol,Any}) :: Sessions.Session
  ( (! haskey(params, Genie.PARAMS_SESSION_KEY) || params[Genie.PARAMS_SESSION_KEY] === nothing) ) &&
      (params[Genie.PARAMS_SESSION_KEY] = Sessions.start(params[Genie.PARAMS_REQUEST_KEY], params[Genie.PARAMS_RESPONSE_KEY])[1])

  params[Genie.PARAMS_SESSION_KEY]
end

end