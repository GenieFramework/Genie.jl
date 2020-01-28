using Pkg
Pkg.activate(".")

using HTTP, Sockets

web_server = HTTP.Servers.Server((req) -> begin
  HTTP.Response("Hello world")
end, devnull)

HTTP.Servers.serve(web_server, Sockets.localhost, 8001, verbose = false)
