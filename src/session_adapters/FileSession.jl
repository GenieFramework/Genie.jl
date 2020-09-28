module FileSession

using Genie
import Serialization, Logging

const SESSIONS_PATH = "sessions"

"""
    write(session::Genie.Sessions.Session) :: Genie.Sessions.Session

Persists the `Session` object to the file system, using the configured sessions folder and returns it.
"""
function write(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  if ! isdir(joinpath(SESSIONS_PATH))
    @warn "Sessions folder $(abspath(SESSIONS_PATH)) does not exist"
    @info "Creating sessions folder at $(abspath(SESSIONS_PATH))"

    mkpath(SESSIONS_PATH)
  end

  open(joinpath(SESSIONS_PATH, session.id), "w") do io
    Serialization.serialize(io, session)
  end

  session
end


"""
    read(session_id::Union{String,Symbol}) :: Union{Nothing,Genie.Sessions.Session}
    read(session::Genie.Sessions.Session) :: Union{Nothing,Genie.Sessions.Session}

Attempts to read from file the session object serialized as `session_id`.
"""
function read(session_id::Union{String,Symbol}) :: Union{Nothing,Genie.Sessions.Session}
  try
    isfile(joinpath(SESSIONS_PATH, session_id)) || return write(Genie.Sessions.Session(session_id))
  catch ex
    @error "Can't check session file"
    @error ex

    write(Genie.Sessions.Session(session_id))
  end

  try
    open(joinpath(SESSIONS_PATH, session_id), "r") do (io)
      Serialization.deserialize(io)
    end
  catch ex
    @error "Can't read session"
    @error ex

    write(Genie.Sessions.Session(session_id))
  end
end

function read(session::Genie.Sessions.Session) :: Union{Nothing,Genie.Sessions.Session}
  read(session.id)
end

#===#
# IMPLEMENTATION

"""
    persist(s::Session) :: Session

Generic method for persisting session data - delegates to the underlying `SessionAdapter`.
"""
function Genie.Sessions.persist(req::Genie.Sessions.HTTP.Request, res::Genie.Sessions.HTTP.Response, params::Dict{Symbol,Any}) :: Tuple{Genie.Sessions.HTTP.Request,Genie.Sessions.HTTP.Response,Dict{Symbol,Any}}
  write(params[Genie.PARAMS_SESSION_KEY])

  req, res, params
end


"""
    load(session_id::String) :: Session

Loads session data from persistent storage.
"""
function Genie.Sessions.load(session_id::String) :: Genie.Sessions.Session
  session = read(session_id)

  session === nothing ? Genie.Sessions.Session(session_id) : (session)
end

end
