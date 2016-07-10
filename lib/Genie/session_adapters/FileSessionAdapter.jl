module FileSessionAdapter

using Genie
using Session
using AppServer

function write()
  file_name = Session.id(AppServer.http_request, AppServer.http_response)
  outfile = open(joinpath(Genie.config.session_folder, file_name), "w")
  serialize(outfile, Session.get())
end

end