using Mux
using Mustache

renderer = Renderer() 

function include_controllers()
	include(abspath("lib/Jinnie/src/controller.jl"))
	for filename in readdir(abspath("app/controllers"))
		include(abspath(joinpath("app/controllers", filename)))
	end
end

function include_libs()
	include(abspath("lib/Jinnie/src/mux_extensions.jl"))
end

function app_setup()
	include_libs()
	include_controllers()

	@app app =
			(
				Mux.defaults,
				stack(Jinnie.req_logger),
				eval(routes)...,
				Mux.notfound()
			)
	
	return app
end

function start_server(server_port = 8000)
	serve( app_setup(), server_port )
end