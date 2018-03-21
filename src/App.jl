"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

using Genie.Configuration

if is_dev()
  @eval using Revise
end

using Genie, YAML, Macros, Logger, Inflector, Util
SEARCHLIGHT_ON && eval(:(using SearchLight, Validation))

IS_IN_APP && (isdefined(:config) || const config = Genie.config)


"""
    load_libs(dir = Genie.LIB_PATH) :: Void

Recursively adds subfolders of lib to LOAD_PATH.
"""
function load_libs(dir = Genie.LIB_PATH) :: Void
  lib_dirs = [d::String for d::String in Util.walk_dir(dir, only_dirs = true)]
  ! isempty(lib_dirs) && push!(LOAD_PATH, lib_dirs...)

  # Util.reload_modules([dir, lib_dirs...], current_module())

  nothing
end


"""
    load_resources(dir = Genie.RESOURCES_PATH) :: Void

Recursively adds subfolders of resources to LOAD_PATH.
"""
function load_resources(dir = Genie.RESOURCES_PATH) :: Void
  res_dirs = Util.walk_dir(dir, only_dirs = true)
  ! isempty(res_dirs) && push!(LOAD_PATH, res_dirs...)

  unique(LOAD_PATH)

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
  loggers_path = abspath("$(Genie.CONFIG_PATH)/loggers.jl")
  if isfile(loggers_path)
    include(loggers_path)
    is_dev() && Revise.track(loggers_path)
  end

  secrets_path = abspath("$(Genie.CONFIG_PATH)/secrets.jl")
  if isfile(secrets_path)
    include(secrets_path)
    is_dev() && Revise.track(secrets_path)
  end

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
      fi = joinpath(dir, i)
      include(fi)
      is_dev() && Revise.track(fi)
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

if IS_IN_APP
  load_configurations()
  load_initializers()
  load_libs()
  load_resources()
end

end
