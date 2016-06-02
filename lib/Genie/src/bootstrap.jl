push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "database_adapters")))

include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

using AppServer
using Migration
using Model
using Tester
using Toolbox

using Reexport
@reexport using Configuration
@reexport using HttpServer
@reexport using Render
@reexport using Render.JSONAPI
@reexport using Util

if is_dev()
  @reexport using Debug
  @reexport using StackTraces
end

function load_configurations()
  include(abspath("config/loggers.jl"))
  include(abspath("config/secrets.jl"))
end

function load_file_templates()
  include(abspath("lib/Genie/src/filetemplates.jl"))
end

function load_models(dir = abspath(joinpath(Genie.APP_PATH, "app", "resources")))
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_models(full_path)
    else 
      if ( i == "model.jl" || i == "validation.jl" ) 
        include(full_path)
      end
    end
  end
end

function load_controller(dir::AbstractString)
  push!(LOAD_PATH, dir)
  controller_files = ["controller", "authorization"]
  for cf in controller_files
    file_path = joinpath(dir, cf * ".jl")
    if isfile(file_path) && isreadable(file_path) 
      include(file_path)
    end
  end
end

function load_initializers()
  dir = abspath(joinpath(Genie.APP_PATH, "config", "initializers"))
  f = readdir(dir)
  for i in f
    include(joinpath(dir, i))
  end
end

function startup(parsed_args::Dict{AbstractString, Any} = Dict(), start_server::Bool = false)
  if ( isempty(parsed_args) ) parsed_args = parse_commandline_args() end
  if parsed_args["s"] == "s" || start_server == true 
    Genie.genie_app.server = Nullable{RemoteRef{Channel{Any}}}(AppServer.spawn(Genie.config.server_port))

    if config.server_workers_count > 1 
      next_port = Genie.config.server_port + 1
      for w in 0:(config.server_workers_count - 1)
        push!(Genie.genie_app.server_workers, AppServer.spawn(next_port))
        next_port += 1
      end
    end 

    while true 
      sleep(1)
    end
  end

  Genie.genie_app.server = Nullable{RemoteRef{Channel{Any}}}()
end

load_configurations()
load_initializers()
load_models()

const SearchLight = Model
export SearchLight