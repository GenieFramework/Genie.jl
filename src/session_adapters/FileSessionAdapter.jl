module FileSessionAdapter

using Genie.Sessions, Genie, Genie.Configuration
import Serialization, Logging

const SESSIONS_PATH = "sessions"

"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the file system, using the configured sessions folder and returns it.
"""
function write(session::Sessions.Session) :: Sessions.Session
  if ! isdir(joinpath(SESSIONS_PATH))
    @warn "Sessions folder $(abspath(SESSIONS_PATH)) does not exist"
    @info "Creating sessions folder at $(abspath(SESSIONS_PATH))"
    mkpath(SESSIONS_PATH)
  end

  try
    open(joinpath(SESSIONS_PATH, session.id), "w") do (io)
      Serialization.serialize(io, session)
    end
  catch ex
    @error "Error serializing session"

    rethrow(ex)
  end

  session
end


"""
    read(session_id::Union{String,Symbol}) :: Union{Nothing,Sessions.Session}
    read(session::Sessions.Session) :: Union{Nothing,Sessions.Session}

Attempts to read from file the session object serialized as `session_id`.
"""
function read(session_id::Union{String,Symbol}) :: Union{Nothing,Sessions.Session}
  try
    isfile(joinpath(SESSIONS_PATH, session_id)) || return write(Session(session_id))
  catch ex
    @error "Can't check session file"
    @error ex

    write(Session(session_id))
  end

  try
    open(joinpath(SESSIONS_PATH, session_id), "r") do (io)
      Serialization.deserialize(io)
    end
  catch ex
    @error "Can't read session"
    @error ex

    write(Session(session_id))
  end
end
function read(session::Sessions.Session) :: Union{Nothing,Sessions.Session}
  read(session.id)
end

end
