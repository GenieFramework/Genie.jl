module Sessions

using SHA, HTTP, Dates, Nullables
using Genie, Genie.Cookies, Genie.Loggers

mutable struct Session
  id::String
  data::Dict{Symbol,Any}
end
Session(id::String) = Session(id, Dict{Symbol,Any}())

export Session

const session_adapter_name = string(Genie.config.session_storage) * "SessionAdapter"
include("session_adapters/$session_adapter_name.jl")
Core.eval(@__MODULE__, Meta.parse("using .$session_adapter_name"))
const SessionAdapter = Core.eval(@__MODULE__, Meta.parse(session_adapter_name))


"""
    id() :: String

Generates a new session id.
"""
function id() :: String
  if ! isdefined(Genie, :SECRET_TOKEN)
    log("Session error", :warn)
    log("$(@__FILE__):$(@__LINE__)", :warn)

    if ! Genie.Configuration.isprod()
      log("Generating temporary secret token", :warn)
      Core.eval(Genie, :(const SECRET_TOKEN = $(Genie.REPL.secret_token())))
    else
      error("Can't compute session id - please make sure SECRET_TOKEN is defined in config/secrets.jl")
    end
  end

  try
    Genie.SECRET_TOKEN * ":" * bytes2hex(sha1(string(Dates.now()))) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256 |> bytes2hex
  catch ex
    log("Session error", :err)
    log("$(@__FILE__):$(@__LINE__)", :err)
    error("Can't compute session id - please make sure SECRET_TOKEN is defined in config/secrets.jl")
  end
end


"""
    id(payload::Union{HTTP.Request,HTTP.Response}) :: String

Attempts to retrieve the session id from the provided `payload` object.
If that is not available, a new session id is created.
"""
function id(payload::Union{HTTP.Request,HTTP.Response}) :: String
  ! isnull(Cookies.get(payload, Genie.config.session_key_name)) &&
    ! isempty(Base.get(Cookies.get(payload, Genie.config.session_key_name))) &&
      return Base.get(Cookies.get(payload, Genie.config.session_key_name))

  id()
end


"""
    id(req::HTTP.Request, res::HTTP.Response) :: String

Attempts to retrieve the session id from the provided request and response objects.
If that is not available, a new session id is created.
"""
function id(req::HTTP.Request, res::HTTP.Response) :: String
  ! isnull(Cookies.get(res, Genie.config.session_key_name)) &&
    ! isempty(Base.get(Cookies.get(res, Genie.config.session_key_name))) &&
      return Base.get(Cookies.get(res, Genie.config.session_key_name))

  ! isnull(Cookies.get(req, Genie.config.session_key_name)) &&
    ! isempty(Base.get(Cookies.get(req, Genie.config.session_key_name))) &&
      return Base.get(Cookies.get(req, Genie.config.session_key_name))

  id()
end


"""
    start(session_id::String, req::HTTP.Request, res::HTTP.Response; options = Dict{String,String}()) :: Session

Initiates a new HTTP session with the provided `session_id`.

# Arguments
- `session_id::String`: the id of the session object
- `req::HTTP.Request`: the request object
- `res::HTTP.Response`: the response object
- `options::Dict{String,String}`: extra options for setting the session cookie, such as `Path` and `HttpOnly`
"""
function start(session_id::String, req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Session
  options = merge(Dict("Path" => "/", "HttpOnly" => true), options)
  Cookies.set!(res, Genie.config.session_key_name, session_id, options)

  load(session_id)
end


"""
    start(req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Session

Initiates a new default session object, generating a new session id.

# Arguments
- `req::HTTP.Request`: the request object
- `res::HTTP.Response`: the response object
- `options::Dict{String,String}`: extra options for setting the session cookie, such as `Path` and `HttpOnly`
"""
function start(req::HTTP.Request, res::HTTP.Response; options::Dict{String,String} = Dict{String,String}()) :: Session
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
    get(s::Session, key::Symbol) :: Nullable

Returns the value stored on the `Session` object `s` as `key`, wrapped in a `Nullable`.
"""
function get(s::Session, key::Symbol) :: Nullable
  haskey(s.data, key) ? Nullable(s.data[key]) : Nullable()
end


"""
    get(s::Session, key::Symbol, default::T) :: T where T

Attempts to retrive the value stored on the `Session` object `s` as `key`.
If the value is not set, it returns the `default`.
"""
function get(s::Session, key::Symbol, default::T) :: T where T
  val = get(s, key)

  isnull(val) ? default : Nullables.get(val)
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

  if isnull(session)
    return Session(session_id)
  else
    return Base.get(session)
  end
end


"""
    session(params::Dict{Symbol,Any}) :: Sessions.Session

Returns the `Session` object associated with the current HTTP request.
"""
function session(params) :: Sessions.Session
  if haskey(params, Genie.PARAMS_SESSION_KEY)
    params[Genie.PARAMS_SESSION_KEY] == nothing &&
      (params[Genie.PARAMS_SESSION_KEY] = start(params[Genie.PARAMS_REQUEST_KEY], params[Genie.PARAMS_RESPONSE_KEY]))

    params[Genie.PARAMS_SESSION_KEY]
  else
    msg = "Missing @params $(Genie.PARAMS_SESSION_KEY) key"
    log(msg, :err)
    error(msg)
  end
end

end