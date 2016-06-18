using Mux

function req_logger(app, req)
  @show req
  response = app(req)
  @show response.status
  @show response
end

function etag(app, req)
  println("in etag") # <-- never gets here
  # compute hash based on response headers and response body, set an etag response header and push up the stack
  response = app(req)
  response = response * "<h3>etag</h3>"
  response.headers["ETag"] = "foo"
end

function rendering(app, req)
  # this should extract the response body and headers and output them
  # this should finally render the response body, setting all the headers
end

@app test = (
  Mux.defaults,
  stack(req_logger), 
  page("/", req -> "<h1>Hello, world!</h1>"), # this should not render, but set the response headers and body and send them up the stack
  stack(etag), # <- never gets here
  stack(rendering) # <- never gets here
)

@sync serve(test)