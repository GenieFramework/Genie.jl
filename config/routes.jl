routes =
	quote
		page(
			"/hellos", 
				post(
					req -> create(Hellos_Controller(), req)
				),
				get(
					req -> index(Hellos_Controller(), req)
				),
				put(
					req -> update(Hellos_Controller(), req)
				),
				delete(
					req -> destroy(Hellos_Controller(), req)
				),
				Mux.notfound()
			),
		@resources(:photos, [:get]),
		page(
			"/",
				req -> index(Hellos_Controller(), req)
			),
		page(
			"/about",
				probabilty(0.1, respond("<h1>Boo!</h1>")),
				respond("<h1>About Me</h1>")
			),
		page(
			"/user/:user",
				req -> "<h1>Hello, $(req[:params][:user])!</h1>"
			)
	end

export routes