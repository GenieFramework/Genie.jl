push!(LOAD_PATH, abspath("./"))
push!(LOAD_PATH, abspath("config"))
push!(LOAD_PATH, abspath("lib/"))
push!(LOAD_PATH, abspath("lib/Jinnie/src"))

const TYPE_FIELD_MAX_DEBUG_LENGTH = 150

using Reexport
using ArgParse
# using Mux
# using Mustache

@reexport using Lazy
@reexport using Memoize
@reexport using JSON
@reexport using Millboard

if is_dev()
  @reexport using Debug
  @reexport using StackTraces
end

include(abspath("lib/Jinnie/src/jinnie_types.jl"))

using Util
using Database
using Model
using Controller
using Migration
using Tester

function load_configurations()
  include(abspath("config/loggers.jl"))
  include(abspath("config/secrets.jl"))
  include(abspath("config/converters.jl"))
  include(abspath("config/renderers.jl"))
  include(abspath("config/routes.jl"))
end

function load_dependencies()
  include(abspath("lib/Jinnie/src/fs_watcher.jl"))
  include(abspath("lib/Jinnie/src/middlewares.jl"))
  include(abspath("lib/Jinnie/src/renderer.jl"))
  include(abspath("lib/Jinnie/src/jinnie.jl"))
  include(abspath("lib/Jinnie/src/filetemplates.jl"))
end

function load_resources(dir = abspath(joinpath(APP_PATH, "app", "resources")))
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_resources(full_path)
    else 
      if ( i == "controller.jl" || i == "model.jl" ) 
        include(full_path)
      end
    end
  end
end

function load_initializers()
  dir = abspath(joinpath(APP_PATH, "config", "initializers"))
  f = readdir(dir)
  for i in f
    include(joinpath(dir, i))
  end
end

function setup_defaults(parsed_args)
  app_env = parsed_args["env"] != nothing ? parsed_args["env"] : Jinnie.config.app_env
  server_port = parsed_args["server-port"] != nothing ? parsed_args["server-port"] : Jinnie.config.server_port
end

function startup(parsed_args = Dict, start_server = false)
  if ( isempty(parsed_args) ) parsed_args = parse_commandline_args() end
  setup_defaults(parsed_args)

  if parsed_args["s"] == "s" || start_server == true 
    if parsed_args["monitor"] == "true" 
      Jinnie.start_server(config.server_port)
      monitor_changes() 
    else
      @sync Jinnie.start_server(config.server_port) 
    end
  end
end

load_configurations()
load_dependencies()
load_initializers()
load_resources()