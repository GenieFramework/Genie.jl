module FileSessionAdapter

using Sessions
using Genie
using Memoize

function write(session)
  try
    open(joinpath(Genie.config.session_folder, session.id), "w") do (io)
      serialize(io, session)
    end
  catch ex
    Genie.log(ex, :err)
  end

  session
end

function read(session_id::AbstractString)
  try
    session = open(joinpath(Genie.config.session_folder, session_id), "r") do (io)
      deserialize(io)
    end
    Nullable{Sessions.Session}(session)
  catch ex
    Genie.log(ex, :debug)
    Nullable{Sessions.Session}()
  end
end
function read(session)
  read(session.id)
end

end