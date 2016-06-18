using Mux

function req_logger(app, req)
  @show req
  return app(req)
end

function controller(app, req)
  # apply routing and match, invoke controller
  # set the response body and potential headers
  # but don't render
  return app(req)
end

function etag(app, req)
  # compute etag hash based on previously 
  # set response body and headers
  return app(req)
end

function cache(app, req)
  # apply some caching 
  return app(req)
end

function renderer(app, req)
  # here render based on what's been set in the app
  # ex - response type (html, json), body, headers, etc
  # return app(req) <- here we're done with the stack
end

@app test = (
  Mux.defaults,
  stack(req_logger),
  stack(controller), 
  stack(etag),
  stack(cache), 
  stack(renderer), 
  Mux.notfound() # <- 404 should probably also be set in the controller, and not be a middleware, because it's part of the routing
)

@sync serve(test)