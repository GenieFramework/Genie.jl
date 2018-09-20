"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

using Revise
using YAML
using Genie

const ASSET_FINGERPRINT = ""

function bootstrap()
  if haskey(ENV, "GENIE_ENV") && isfile(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
    isfile(joinpath(Genie.CONFIG_PATH, "global.jl")) && include(joinpath(Genie.CONFIG_PATH, "global.jl"))
    include(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
  else
    ENV["GENIE_ENV"] = Configuration.DEV
    eval(@__MODULE__, Meta.parse("config = Configuration.Settings(app_env = Configuration.DEV)"))
  end
end

end


### Main

using Genie.Loggers, Genie.Configuration


"""
    load_libs(dir = Genie.LIB_PATH) :: Nothing

Recursively adds subfolders of lib to LOAD_PATH.
"""
function load_libs(root_dir = Genie.LIB_PATH) :: Nothing
  push!(LOAD_PATH, root_dir)
  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, p)
    end
  end

  nothing
end


"""
    load_resources(dir = Genie.RESOURCES_PATH) :: Nothing

Recursively adds subfolders of resources to LOAD_PATH.
"""
function load_resources(root_dir = Genie.RESOURCES_PATH) :: Nothing
  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end


function load_helpers(root_dir = Genie.HELPERS_PATH) :: Nothing
  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

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
    load_configurations() :: Nothing

Loads (includes) the framework's configuration files.
"""
function load_configurations() :: Nothing
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
    load_initializers() :: Nothing

Loads (includes) the framework's initializers.
"""
function load_initializers() :: Nothing
  dir = abspath(joinpath(Genie.CONFIG_PATH, "initializers"))

  if isdir(dir)
    f = readdir(dir)
    for i in f
      fi = joinpath(dir, i)
      if endswith(fi, ".jl")
        include(fi)
        is_dev() && Revise.track(fi)
      end
    end
  end

  nothing
end


"""
    load_routes_definitions() :: Nothing

Loads the routes file.
"""
function load_routes_definitions(fail_on_error = is_dev()) :: Nothing
  try
    if isfile(Genie.ROUTES_FILE_NAME)
      include(Genie.ROUTES_FILE_NAME)
      is_dev() && Revise.track(Genie.ROUTES_FILE_NAME)
    end
  catch ex
    log(ex, :warn)

    fail_on_error && rethrow(ex)
  end

  nothing
end


"""
    load_channels_definitions() :: Nothing

Loads the channels file.
"""
function load_channels_definitions(fail_on_error = is_dev()) :: Nothing
  try
    if isfile(Genie.CHANNELS_FILE_NAME)
      include(Genie.CHANNELS_FILE_NAME)
      is_dev() && Revise.track(Genie.CHANNELS_FILE_NAME)
    end
  catch ex
    log(ex, :err)

    fail_on_error && rethrow(ex)
  end

  nothing
end


"""
    secret_token() :: String

Wrapper around /config/secrets.jl SECRET_TOKEN `const`.
"""
function secret_token() :: String
  if @isdefined SECRET_TOKEN
    SECRET_TOKEN
  else
    log("SECRET_TOKEN not configured - please make sure that you have a valid secrets.jl file.
          You can generate a new secrets.jl file with a random SECRET_TOKEN using Genie.REPL.write_secrets_file()
          or use the included /app/config/secrets.jl.example file as a model.", :warn)
    st = Genie.REPL.secret_token()
    Core.eval(Genie, Meta.parse("""const SECRET_TOKEN = "$st" """))

    st
  end
end


function load() :: Nothing
  App.bootstrap()

  load_configurations()

  Loggers.log_path!()
  Loggers.empty_log_queue()

  load_initializers()
  load_helpers()

  load_libs()
  load_resources()

  load_routes_definitions()
  load_channels_definitions()

  nothing
end
