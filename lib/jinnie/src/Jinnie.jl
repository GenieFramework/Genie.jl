include(abspath("lib/Mux/src/Mux.jl"))
include(abspath("lib/Mustache/src/Mustache.jl"))

using Mux
using Mustache
using Jinnie_Middlewares

function include_controllers()
	include(abspath("lib/Jinnie/src/controller.jl"))
	for filename in readdir(abspath("app/controllers"))
		include(abspath(joinpath("app/controllers", filename)))
	end
end

function include_libs()
	include(abspath("lib/Jinnie/src/mux_extensions.jl"))
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

function _render(layout_file::AbstractString, view_file::AbstractString, data::Dict)
	view_stream = open(view_file)
	data["yield"] = Mustache.render(readall(view_stream), data)
	layout_stream = open(layout_file)
	Mustache.render(readall(layout_stream), data)
end
function render(req::Dict; mime="html", renderer="mustache", data=Dict())
	_render(abspath("app/views/layouts/application.html.mustache"), abspath("app/views/$(req[:controller])/$(req[:action]).$mime.$renderer"), data)
end
function render(content::AbstractString; data=Dict())
	Mustache.render(content, data)
end