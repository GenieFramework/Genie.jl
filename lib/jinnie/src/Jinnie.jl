renderer = Renderer() 

function include_resources(dir = abspath(joinpath("$APP_PATH", "app", "resources")))
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      include_resources(full_path)
    else 
      if ( i == "controller.jl" || i == "model.jl" ) 
        include(full_path)
      end
    end
  end
end

function include_initializers()
  dir = abspath(joinpath("$APP_PATH", "initializers"))
  f = readdir(dir)
  for i in f
    include(joinpath(dir, i))
  end
end

function include_libs()
	include(abspath("lib/Jinnie/src/controller.jl"))
  include(abspath("lib/Jinnie/src/model.jl"))
	include(abspath("lib/Jinnie/src/mux_extensions.jl"))
end

function start_server(server_port = 8000; reload = false)
	@app app =
			(
				Mux.defaults,
				Mux.stack(Jinnie.req_logger),
				eval(routes)...,
				Mux.notfound()
			)

	if reload return end

	serve(app, server_port)
end