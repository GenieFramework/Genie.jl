module FileSessionAdapter

using Nullables
using Genie.Sessions, Genie, Genie.Configuration
using Serialization, Logging

"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the file system, using the configured sessions folder and returns it.
"""
function write(session::Sessions.Session) :: Sessions.Session
  if ! isdir(joinpath(Genie.SESSIONS_PATH))
    @warn "Sessions folder $(abspath(Genie.SESSIONS_PATH)) does not exist"
    @info "Creating sessions folder at $(abspath(Genie.SESSIONS_PATH))"
    mkpath(Genie.SESSIONS_PATH)
  end

  try
    open(joinpath(Genie.SESSIONS_PATH, session.id), "w") do (io)
      serialize(io, session)
    end
  catch ex
    @error "Error when serializing session"

    rethrow(ex)
  end

  session
end


"""
    read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
    read(session::Sessions.Session) :: Nullable{Sessions.Session}

Attempts to read from file the session object serialized as `session_id`.
"""
function read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
  try
    isfile(joinpath(Genie.SESSIONS_PATH, session_id)) || return Nullable{Sessions.Session}(write(Session(session_id)))
  catch ex
    @error "Can't check session file"
    @error ex

    Nullable{Sessions.Session}(write(Session(session_id)))
  end

  try
    session = open(joinpath(Genie.SESSIONS_PATH, session_id), "r") do (io)
      deserialize(io)
    end

    Nullable{Sessions.Session}(session)
  catch ex
    @error "Can't read session"
    @error ex

    Nullable{Sessions.Session}(write(Session(session_id)))
  end
end
function read(session::Sessions.Session) :: Nullable{Sessions.Session}
  read(session.id)
end

end
