"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

using Genie, SearchLight, YAML, Validation, Macros, Logger, Inflector, Util

IS_IN_APP && const config = Genie.config


"""
    load_libs(dir = Genie.LIB_PATH) :: Void

Recursively adds subfolders of lib to LOAD_PATH.
"""
function load_libs(dir = Genie.LIB_PATH) :: Void
  lib_dirs = [d for d in Task( ()-> Util.walk_dir(dir, only_dirs = true) )]
  ! isempty(lib_dirs) && push!(LOAD_PATH, lib_dirs...)

  nothing
end


"""
    load_resources(dir = Genie.RESOURCES_PATH) :: Void

Recursively adds subfolders of resources to LOAD_PATH.
"""
function load_resources(dir = Genie.RESOURCES_PATH) :: Void
  res_dirs = [d for d in Task( ()-> Util.walk_dir(dir, only_dirs = true) )]
  ! isempty(res_dirs) && push!(LOAD_PATH, res_dirs...)

  nothing
end


"""
    load_models(dir = Genie.RESOURCES_PATH) :: Void

Loads (includes) all available `model` and `validator` files.
The modules are included in the `App` module.
"""
function load_models(dir = Genie.RESOURCES_PATH) :: Void
  ! isdir(abspath(dir)) && return nothing

  dir_contents = readdir(abspath(dir))

  for i in dir_contents
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_models(full_path)
    else
      if i == Genie.GENIE_MODEL_FILE_NAME
        eval(App, :(include($full_path)))
        isfile(joinpath(dir, Genie.GENIE_VALIDATOR_FILE_NAME)) && eval(Validation, :(include(joinpath($dir, $(Genie.GENIE_VALIDATOR_FILE_NAME)))))
      end
    end
  end

  nothing
end


"""
    load_controller(dir::String) :: Void

Loads (includes) the `controller` file that corresponds to the currently matched route.
The modules are included in the `App` module.
"""
function load_controller(dir::String) :: Void
  push!(LOAD_PATH, dir)
  file_path = joinpath(dir, Genie.GENIE_CONTROLLER_FILE_NAME)
  isfile(file_path) ? eval(App, :(include($file_path))) : Logger.log("Failed loading controller $dir", :err)

  nothing
end


"""
    load_resource_controller(resource::String) :: Void

Load the controller file corresponding to `resource`.
"""
function load_resource_controller(resource::String) :: Void
  Inflector.is_singular(resource) && (resource = Inflector.to_plural(resource) |> Base.get)
  load_controller(joinpath(Genie.RESOURCES_PATH, resource))
end


"""
    load_channel(dir::String) :: Void

Loads (includes) the `channel` file that corresponds to the currently matched channel.
The modules are included in the `App` module.
"""
function load_channel(dir::String) :: Void
  push!(LOAD_PATH, dir)
  file_path = joinpath(dir, Genie.GENIE_CHANNEL_FILE_NAME)
  isfile(file_path) && eval(App, :(include($file_path)))

  nothing
end


"""
    load_resource_channel(resource::String) :: Void

Load the channel file corresponding to `resource`.
"""
function load_resource_channel(resource::String) :: Void
  Inflector.is_singular(resource) && (resource = Inflector.to_plural(resource) |> Base.get)
  load_channel(joinpath(Genie.RESOURCES_PATH, resource))
end


"""
    export_controllers(controllers::String) :: Void

Make `controller` modules available autside the `App` module.
"""
function export_controllers(controllers::String) :: Void
  eval(App, parse("""export $(split(controllers, ".")[1])"""))

  nothing
end


"""
    export_channels(controllers::AbstractString) :: Void

Make `controller` modules available autside the `App` module.
"""
function export_channels(channels::String) :: Void
  eval(App, parse("""export $(split(channels, ".")[1])"""))

  nothing
end


"""
    load_acl(dir::String) :: Dict{Any,Any}

Loads the ACL file associated with the invoked `controller` and returns the rules.
"""
function load_acl(dir::String) :: Dict{Any,Any}
  file_path = joinpath(dir, Genie.GENIE_AUTHORIZATOR_FILE_NAME)
  isfile(file_path) ? YAML.load(open(file_path)) : Dict{Any,Any}()
end


"""
    load_configurations() :: Void

Loads (includes) the framework's configuration files.
"""
function load_configurations() :: Void
  isfile(abspath("$(Genie.CONFIG_PATH)/loggers.jl")) && include(abspath("$(Genie.CONFIG_PATH)/loggers.jl"))
  isfile(abspath("$(Genie.CONFIG_PATH)/secrets.jl")) && include(abspath("$(Genie.CONFIG_PATH)/secrets.jl"))

  nothing
end


"""
    load_initializers() :: Void

Loads (includes) the framework's initializers.
"""
function load_initializers() :: Void
  dir = abspath(joinpath(Genie.CONFIG_PATH, "initializers"))

  if isdir(dir)
    f = readdir(dir)
    for i in f
      include(joinpath(dir, i))
    end
  end

  nothing
end


"""
    secret_token() :: String

Wrapper around /config/secrets.jl SECRET_TOKEN `const`.
"""
function secret_token() :: String
  isdefined(App, :SECRET_TOKEN) ||
    throw("SECRET_TOKEN not configured - please make sure that you have a valid secrets.jl file. You can generate a new secrets.jl file with a random SECRET_TOKEN using Genie.REPL.write_secrets_file() or use the included /app/config/secrets.jl.example file as a model.")

  SECRET_TOKEN
end

load_configurations()
load_initializers()
IS_IN_APP && load_libs()
IS_IN_APP && load_resources()
load_models()

end
