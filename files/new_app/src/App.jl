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


"""
"""
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
    load_configurations() :: Nothing

Loads (includes) the framework's configuration files.
"""
function load_configurations() :: Nothing
  loggers_path = abspath("$(Genie.CONFIG_PATH)/loggers.jl")
  if isfile(loggers_path)
    include(loggers_path)
    Revise.track(@__MODULE__, loggers_path)
  end

  secrets_path = abspath("$(Genie.CONFIG_PATH)/secrets.jl")
  if isfile(secrets_path)
    include(secrets_path)
    Revise.track(@__MODULE__, secrets_path)
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
        try
          Revise.track(@__MODULE__, fi)
        catch
          log("Failed Revise tracking of $fi", :warn)
        end
      end
    end
  end

  nothing
end


"""
    load_routes_definitions() :: Nothing

Loads the routes file.
"""
function load_routes_definitions(fail_on_error = isdev()) :: Nothing
  try
    if isfile(Genie.ROUTES_FILE_NAME)
      include(Genie.ROUTES_FILE_NAME)
      Revise.track(@__MODULE__, Genie.ROUTES_FILE_NAME)
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
function load_channels_definitions(fail_on_error = isdev()) :: Nothing
  try
    if isfile(Genie.CHANNELS_FILE_NAME)
      include(Genie.CHANNELS_FILE_NAME)
      Revise.track(@__MODULE__, Genie.CHANNELS_FILE_NAME)
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


"""
    newmodel(model_name::String) :: Nothing

Creates a new `model` file.
"""
function newmodel(model_name::String) :: Nothing
  SearchLight.Generator.new_model(model_name)
  load_resources()

  nothing
end


"""
    newcontroller(controller_name::String) :: Nothing

Creates a new `controller` file.
"""
function newcontroller(controller_name::String) :: Nothing
  Genie.Generator.new_controller(Dict{String,Any}("controller:new" => controller_name))
  load_resources()

  nothing
end


"""
    newchannel(channel_name::String) :: Nothing

Creates a new `channel` file.
"""
function newchannel(channel_name::String) :: Nothing
  Genie.Generator.new_channel(Dict{String,Any}("channel:new" => channel_name))
  load_resources()

  nothing
end


"""
    newresource(resource_name::String) :: Nothing

Creates all the files associated with a new resource.
"""
function newresource(resource_name::String) :: Nothing
  Genie.Generator.new_resource(Dict{String,Any}("resource:new" => resource_name))

  try
    SearchLight.Generator.new_resource(uppercasefirst(resource_name))
  catch ex
    log("Skipping SearchLight", :warn)
  end

  load_resources()

  nothing
end


"""
    newmigration(migration_name::String) :: Nothing

Creates a new migration file.
"""
function newmigration(migration_name::String) :: Nothing
  SearchLight.Generator.new_migration(Dict{String,Any}("migration:new" => migration_name))
end


"""
"""
function newtablemigration(migration_name::String) :: Nothing
  SearchLight.Generator.new_table_migration(Dict{String,Any}("migration:new" => migration_name))
end


"""
    newtask(task_name::String) :: Nothing

Creates a new `Task` file.
"""
function newtask(task_name::String) :: Nothing
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Genie.Toolbox.new(Dict{String,Any}("task:new" => task_name), Genie.config)
end


"""
    startup()

Starts the web server.
```
"""
function startup(port::Int = 8000, host::String = Genie.config.server_host;
                  wsport::Int = port + 1, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing)

  Genie.AppServer.startup(port, host, ws_port = wsport, async = async, verbose = verbose, ratelimit = ratelimit)
end


"""
"""
function load() :: Nothing
  App.bootstrap()

  load_configurations()

  Genie.Loggers.log_path!()
  Genie.Loggers.empty_log_queue()

  load_initializers()
  load_helpers()

  load_libs()
  load_resources()

  load_routes_definitions()
  load_channels_definitions()

  nothing
end
