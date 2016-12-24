module FileSessionAdapter
using Sessions, Genie, Logger

function write(session)
  try
    open(joinpath(Genie.config.session_folder, session.id), "w") do (io)
      serialize(io, session)
    end
  catch ex
    Logger.log("Error when serializing session $session in $(@__FILE__):$(@__LINE__)")
    Logger.@location()
  end

  session
end

function read(session_id::AbstractString) :: Nullable{Sessions.Session}
  try
    session = open(joinpath(Genie.config.session_folder, session_id), "r") do (io)
      deserialize(io)
    end

    Nullable{Sessions.Session}(session)
  catch ex
    Logger.log("Can't read session $(joinpath(Genie.config.session_folder, session_id))", :err)
    Logger.@location()

    Nullable{Sessions.Session}()
  end
end
function read(session)
  read(session.id)
end

end
