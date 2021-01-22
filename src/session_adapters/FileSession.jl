module FileSession

using Genie
import Serialization, Logging

const SESSIONS_PATH = "sessions"

"""
    write(session::Genie.Sessions.Session) :: Genie.Sessions.Session

Persists the `Session` object to the file system, using the configured sessions folder and returns it.
"""
function write(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  if !isdir(joinpath(SESSIONS_PATH))
    @warn "Sessions folder $(abspath(SESSIONS_PATH)) does not exist"
    @info "Creating sessions folder at $(abspath(SESSIONS_PATH))"

    try
      mkpath(SESSIONS_PATH)
    catch ex
      @error "Can't create session storage path $SESSIONS_PATH"
      @error ex
    end
  end

  try
    write_session(session)

    return session
  catch ex
    @error "Failed to store session data"
    @error ex
  end

  try
    @warn "Resetting session"

    session = Genie.Sessions.Session(Genie.Sessions.id())
    Genie.Cookies.set!(Genie.Router._params_(Genie.PARAMS_RESPONSE_KEY), Genie.config.session_key_name, session.id, Genie.config.session_options)
    write_session(session)
    Genie.Router._params_(Genie.PARAMS_SESSION_KEY, session)

    return session
  catch ex
    @error "Failed to regenerate and store session data. Giving up."
    @error ex
  end

  session
end


function write_session(session::Genie.Sessions.Session)
  open(joinpath(SESSIONS_PATH, session.id), "w") do io
    Serialization.serialize(io, session)
  end
end


"""
    read(session_id::Union{String,Symbol}) :: Union{Nothing,Genie.Sessions.Session}
    read(session::Genie.Sessions.Session) :: Union{Nothing,Genie.Sessions.Session}

Attempts to read from file the session object serialized as `session_id`.
"""
function read(session_id::Union{String,Symbol}) :: Union{Nothing,Genie.Sessions.Session}
  isfile(joinpath(SESSIONS_PATH, session_id)) || return nothing

  try
    open(joinpath(SESSIONS_PATH, session_id), "r") do (io)
      Serialization.deserialize(io)
    end
  catch ex
    @error "Can't read session"
    @error ex
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

  isnothing(session) ? Genie.Sessions.Session(session_id) : (session)
end

end
