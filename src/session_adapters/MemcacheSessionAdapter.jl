module MemcacheSessionAdapter

using Sessions, Genie, Loggers, Genie.Configuration, App, Memcache, JSON, Nullables


"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the Memcache storage, using the configured DB.
"""
function write(session::Sessions.Session) :: Sessions.Session
  try
    Memcache.set(App.MEMCACHECONN, session.id, JSON.json(session.data))
  catch ex
    log("Error when serializing session in $(@__FILE__):$(@__LINE__)", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

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
    session = Sessions.Session(session_id, JSON.parse(Memcache.get(App.MEMCACHECONN, session_id)))

    return isnull(session) ? Nullable{Sessions.Session}() : Nullable{Sessions.Session}(session)
  catch ex
    log("Can't read session", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    return Nullable{Sessions.Session}(write(Sessions.Session(session_id)))
  end
end
function read(session::Sessions.Session) :: Nullable{Sessions.Session}
  read(session.id)
end


end
