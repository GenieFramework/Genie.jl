using Mux
using Jinnie_Middlewares

abstract Jinnie_Controller

function include_controllers()
	for filename in readdir(abspath("app/controllers"))
		include(abspath(joinpath("app/controllers", filename)))
	end
end

function include_libs()
	include(abspath("lib/jinnie/jinnie_mux_extensions.jl"))
end

function router_setup()
	include_libs()
	include_controllers()

	@app app =
			(
				Mux.defaults,
				stack(Jinnie_Middlewares.req_logger),
				eval(routes)...,
				Mux.notfound()
			)

	return app
end

function start_server()
	info("Starting server")
	@sync serve( router_setup() )
end