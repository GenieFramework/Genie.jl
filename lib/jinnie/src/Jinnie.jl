import Base.string
import Base.print
import Base.show

export config
export JinnieModel, JinnieType, M, Model, Database

abstract JinnieType
string{T<:JinnieType}(io::IO, t::T) = jinnietype_to_string(t)
print{T<:JinnieType}(io::IO, t::T) = print(io, jinnietype_to_print(t))
show{T<:JinnieType}(io::IO, t::T) = print(io, jinnietype_to_print(t))

abstract JinnieModel <: JinnieType

renderer = Renderer() 

function include_resources(dir = abspath(joinpath(APP_PATH, "app", "resources")))
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
  dir = abspath(joinpath(APP_PATH, "config", "initializers"))
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

function jinnietype_to_string{T<:JinnieType}(m::T)
  output = "$(typeof(m)) <: $(super(typeof(m)))" * "\n"
  for f in fieldnames(m)
    value = getfield(m, symbol(f))
    if  isa(value, AbstractString) && length(value) > Jinnie.TYPE_FIELD_MAX_DEBUG_LENGTH 
        value = replace(value[1:TYPE_FIELD_MAX_DEBUG_LENGTH], "\n", " ") * "..." 
    end
    output = output * "  + $f \t $(value) \n"
  end
  
  output
end

function jinnietype_to_print{T<:JinnieType}(m::T)
  output = "$(typeof(m)) <: $(super(typeof(m)))" * "\n"
  output *= string(Millboard.table(M.to_string_dict(m))) * "\n"
  
  output
end

function to_dict(m::Any; all_fields = false) 
  [string(f) => getfield(m, Symbol(f)) for f in fieldnames(m)]
end

function to_string_dict(m::Any; all_fields = false) 
  [string(f) => string(getfield(m, Symbol(f))) for f in fieldnames(m)]
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