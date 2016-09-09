using Reexport

push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "database_adapters")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "cache_adapters")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "session_adapters")))

push!(LOAD_PATH, abspath(joinpath("app", "resources")))
push!(LOAD_PATH, abspath(joinpath("app", "helpers")))

include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

using AppServer
using Inflector
using Migration
using Model
using Tester
using Toolbox
using YAML
# using Hooks

@reexport using Configuration
@reexport using Cache
@reexport using Cookies
@reexport using DateParser
@reexport using Ejl
@reexport using HttpServer
@reexport using Input
@reexport using Render
@reexport using Render.JSONAPI
@reexport using Router
@reexport using Sessions
@reexport using StackTraces
@reexport using SHA
@reexport using URIParser
@reexport using Util

if is_dev()
  @reexport using Debug
  @reexport using StackTraces
end

function load_configurations()
  include(abspath("config/loggers.jl"))
  isfile(abspath("config/secrets.jl")) && include(abspath("config/secrets.jl"))
end

function load_models(dir = abspath(joinpath(Genie.APP_PATH, "app", "resources")))
  dir_contents = readdir(abspath(dir))

  for i in dir_contents
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_models(full_path)
    else
      if i == GENIE_MODEL_FILE_NAME
        include(full_path)
        isfile(joinpath(dir, GENIE_VALIDATOR_FILE_NAME)) && eval(Validation, :(include(joinpath($dir, $GENIE_VALIDATOR_FILE_NAME))))
      end
    end
  end
end

function load_controller(dir::AbstractString)
  push!(LOAD_PATH, dir)
  file_path = joinpath(dir, GENIE_CONTROLLER_FILE_NAME)
  if isfile(file_path) && isreadable(file_path)
    include(file_path)
  end
end

function export_controllers(controllers::AbstractString)
  parts = split(controllers, ".")
  eval(Genie, parse("export $(parts[1])"))
end

function load_initializers()
  dir = abspath(joinpath(Genie.APP_PATH, "config", "initializers"))

  if isdir(dir)
    f = readdir(dir)
    for i in f
      include(joinpath(dir, i))
    end
  end
end

function load_acl(dir::AbstractString)
  file_path = joinpath(dir, GENIE_AUTHORIZATION_FILE_NAME)
  if isfile(file_path) && isreadable(file_path)
    YAML.load(open(file_path))
  else
    Dict{Any,Any}
  end
end

function reload_helpers(in_module = current_module())
  for n in names(in_module, true)
    endswith(string(n), "Helper") && typeof(eval(n)) == Module && reload(string(n))
  end
end

function startup(parsed_args::Dict{AbstractString,Any} = Dict{AbstractString,Any}(), start_server::Bool = false)
  isempty(parsed_args) && (parsed_args = parse_commandline_args())

  server_workers = Vector{RemoteRef{Channel{Any}}}()

  if parsed_args["s"] == "s" || start_server == true
    server_workers = AppServer.spawn!(server_workers, Genie.config.server_port)

    println()
    Genie.log("Started Genie server session", :info)

    while true
      sleep(1)
    end
  end

  server_workers
end

function cache_enabled()
  Genie.config.cache_duration > 0
end

load_configurations()
load_initializers()
load_models()

const SearchLight = const M = Model
export SearchLight, M
