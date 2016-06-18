using Mux

function logger(app, req)
	info("In logger")
	@show req
	return app(req)
end

@app test = (
  Mux.defaults,
	stack(logger),
  page(respond("<h1>Hello Planet!</h1>")),
	page(
		"/test",
		req -> testing(req)
	),
  page("/about",
       probabilty(0.1, respond("<h1>Boo!</h1>")),
       respond("<h1>About Me</h1>")),
  page("/user/:user", req -> "<h1>Hello, $(req[:params][:user])!</h1>"),
  Mux.notfound()
)

function testing(req)
	info("In test function")
	"<h1>Testing</h1>"
end

@sync serve(test)
exit(0)
