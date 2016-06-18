using HttpServer

http = HttpHandler() do req::Request, res::Response
    Response( ismatch(r"^/hello", req.resource) ? "All good dude" : 404 )
end

server = Server( http )
@spawn run( server, 8001 )

while true 
  sleep(1)
end