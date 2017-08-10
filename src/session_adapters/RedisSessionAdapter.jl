module RedisSessionAdapter

using Sessions, Genie, Logger, Configuration, App, Redis, JSON


"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the Redis storage, using the configured DB.
"""
function write(session::Sessions.Session) :: Sessions.Session
  try
    Redis.set(App.REDISCONN, session.id, JSON.json(session.data))
  catch ex
    Logger.log("Error when serializing session in $(@__FILE__):$(@__LINE__)", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

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
    session = Sessions.Session(session_id, JSON.parse(Redis.get(App.REDISCONN, session_id)))

    return isnull(session) ? Nullable{Sessions.Session}() : Nullable{Sessions.Session}(session)
  catch ex
    Logger.log("Can't read session", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    return Nullable{Sessions.Session}(write(Sessions.Session(session_id)))
  end
end
function read(session::Sessions.Session) :: Nullable{Sessions.Session}
  read(session.id)
end


end
