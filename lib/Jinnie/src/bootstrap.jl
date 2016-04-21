push!(LOAD_PATH, abspath("./"))
push!(LOAD_PATH, abspath("config"))
push!(LOAD_PATH, abspath("lib/"))
push!(LOAD_PATH, abspath("lib/Jinnie/src"))

const TYPE_FIELD_MAX_DEBUG_LENGTH = 150

using Reexport
using ArgParse
using Requests
using Mustache

@reexport using Lazy
@reexport using Memoize
@reexport using JSON
@reexport using Millboard
@reexport using HttpServer
@reexport using DateParser

if is_dev()
  @reexport using Debug
  @reexport using StackTraces
end

include(abspath("lib/Jinnie/src/jinnie_types.jl"))

using Database
using Controller
using Toolbox
using Migration
using Tester
using AppServer
using Router

@reexport using Model
@reexport using Render
@reexport using Render.JSONAPI
@reexport using Util

function load_configurations()
  include(abspath("config/loggers.jl"))
  include(abspath("config/secrets.jl"))
end

function load_dependencies()
  include(abspath("lib/Jinnie/src/middlewares.jl"))
  include(abspath("lib/Jinnie/src/jinnie.jl"))
  include(abspath("lib/Jinnie/src/filetemplates.jl"))
end

function load_resources(dir = abspath(joinpath(Jinnie.APP_PATH, "app", "resources")))
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
  dir = abspath(joinpath(Jinnie.APP_PATH, "config", "initializers"))
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
    Jinnie.jinnie_app.server = Nullable{RemoteRef{Channel{Any}}}(AppServer.spawn(Jinnie.config.server_port))

    if parsed_args["monitor"] == "true" 
      include(abspath("lib/Jinnie/src/fs_watcher.jl"))
      monitor_changes() 
    end

    while true 
      sleep(1)
    end
  end

  Jinnie.jinnie_app.server = Nullable{RemoteRef{Channel{Any}}}()
end

load_configurations()
load_dependencies()
load_initializers()
load_resources()