module Sessions

using Genie, SHA, HttpServer, Cookies, App, Helpers, Router

type Session
  id::String
  data::Dict{Symbol,Any}
end
Session(id::String) = Session(id, Dict{Symbol,Any}())

export Session

if IS_IN_APP
  const session_adapter_name = string(Genie.config.session_storage) * "SessionAdapter"
  eval(parse("using $session_adapter_name"))
  const SessionAdapter = eval(parse(session_adapter_name))
end


"""
    id() :: String
    id(req::Request) :: String
    id(req::Request, res::Response) :: String

Generates a unique session id.
"""
function id() :: String
  try
    App.SECRET_TOKEN * ":" * bytes2hex(sha1(string(Dates.now()))) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256 |> bytes2hex
  catch ex
    # Genie.log(ex, :err)
    error("Can't compute session id - please make sure SECRET_TOKEN is defined in config/secrets.jl")
  end
end
function id(req::Request) :: String
  ! isnull(Cookies.get(req, Genie.config.session_key_name)) && return Base.get(Cookies.get(req, Genie.config.session_key_name))

  id()
end
function id(req::Request, res::Response) :: String
  ! isnull(Cookies.get(res, Genie.config.session_key_name)) && return Base.get(Cookies.get(res, Genie.config.session_key_name))
  ! isnull(Cookies.get(req, Genie.config.session_key_name)) && return Base.get(Cookies.get(req, Genie.config.session_key_name))

  id()
end


"""
    start(session_id::String, req::Request, res::Response; options = Dict{String,String}()) :: Session
    start(req::Request, res::Response) :: Session

Initiates a session.
"""
function start(session_id::String, req::Request, res::Response; options = Dict{String,String}()) :: Session
  options = merge(Dict("Path" => "/", "HttpOnly" => "", "Expires" => "0"), options)
  Cookies.set!(res, Genie.config.session_key_name, session_id, options)
  load(session_id)
end
function start(req::Request, res::Response) :: Session
  start(id(req, res), req, res)
end


"""
    set!(s::Session, key::Symbol, value::Any) :: Session

Stores `value` as `key` on the `Session` `s`.
"""
function set!(s::Session, key::Symbol, value::Any) :: Session
  s.data[key] = value

  s
end


"""
    get(s::Session, key::Symbol) :: Nullable

Returns the value stored on the `Session` `s` as `key`, wrapped in a `Nullable`.
"""
function get(s::Session, key::Symbol) :: Nullable
  return  if haskey(s.data, key)
            Nullable(s.data[key])
          else
            Nullable()
          end
end


"""
    get!!(s::Session, key::Symbol)

Attempts to read the value stored on the `Session` `s` as `key` - throws an exception if the `key` does not exist.
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
    is_set(s::Session, key::Symbol) :: Bool

Checks wheter or not `key` exists on the `Session` `s`.
"""
function is_set(s::Session, key::Symbol) :: Bool
  haskey(s.data, key)
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

end
