"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

using Revise
using Genie

const ASSET_FINGERPRINT = ""


### PRIVATE ###


"""
    bootstrap(context::Module = @__MODULE__) :: Nothing

Kickstarts the loading of a Genie app by loading the environment settings.
"""
function bootstrap(context::Module = @__MODULE__) :: Nothing
  if haskey(ENV, "GENIE_ENV") && isfile(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
    isfile(joinpath(Genie.ENV_PATH, "global.jl")) && include(joinpath(Genie.ENV_PATH, "global.jl"))
    include(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
  else
    ENV["GENIE_ENV"] = Configuration.DEV
    eval(context, Meta.parse("config = Configuration.Settings(app_env = Configuration.DEV)"))
  end

  Core.eval(Genie, Meta.parse("config = App.config"))

  nothing
end

end


### THIS IS LOADED INTO the Genie module !!!


using .Loggers, .Configuration


### PUBLIC ###


"""
    newmodel(model_name::String; context = @__MODULE__) :: Nothing

Creates a new SearchLight `model` file.
"""
function newmodel(model_name::String; context::Module = @__MODULE__) :: Nothing
  Core.eval(context, :(SearchLight.Generator.newmodel($model_name)))
  load_resources()

  nothing
end


"""
    newcontroller(controller_name::String) :: Nothing

Creates a new `controller` file. If `pluralize` is `false`, the name of the controller is not automatically pluralized.
"""
function newcontroller(controller_name::String; pluralize::Bool = true) :: Nothing
  Generator.newcontroller(Dict{String,Any}("controller:new" => controller_name), pluralize = pluralize)
  load_resources()

  nothing
end


"""
    newresource(resource_name::String; pluralize::Bool = true, context::Module = @__MODULE__) :: Nothing

Creates all the files associated with a new resource.
If `pluralize` is `false`, the name of the resource is not automatically pluralized.
"""
function newresource(resource_name::String; pluralize::Bool = true, context::Module = @__MODULE__) :: Nothing
  Generator.newresource(Dict{String,Any}("resource:new" => resource_name), pluralize = pluralize)

  try
    Core.eval(context, :(SearchLight.Generator.newresource(uppercasefirst($resource_name))))
  catch ex
    log(ex, :error)
    log("Skipping SearchLight", :warn)
  end

  load_resources()

  nothing
end


"""
    newmigration(migration_name::String, context::Module = @__MODULE__) :: Nothing

Creates a new SearchLight migration file.
"""
function newmigration(migration_name::String; context::Module = @__MODULE__) :: Nothing
  Core.eval(context, :(SearchLight.Generator.new_migration(Dict{String,Any}("migration:new" => $migration_name))))

  nothing
end


"""
    newtablemigration(migration_name::String) :: Nothing

Creates a new migration prefilled with code for creating a new table.
"""
function newtablemigration(migration_name::String; context::Module = @__MODULE__) :: Nothing
  Core.eval(context, :(SearchLight.Generator.new_table_migration(Dict{String,Any}("migration:new" => $migration_name))))

  nothing
end


"""
    newtask(task_name::String) :: Nothing

Creates a new Genie `Task` file.
"""
function newtask(task_name::String) :: Nothing
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Genie.Toolbox.new(Dict{String,Any}("task:new" => task_name), Genie.config)

  nothing
end


### PRIVATE ###


"""
    load_libs(root_dir::String = Genie.LIB_PATH) :: Nothing

Recursively adds subfolders of `lib/` to LOAD_PATH.
The `lib/` folder, if present, is designed to host user code in the form of .jl files.
This function loads user code into the Genie app.
"""
function load_libs(root_dir::String = LIB_PATH) :: Nothing
  isdir(root_dir) || return nothing

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
    load_resources(root_dir::String = RESOURCES_PATH) :: Nothing

Recursively adds subfolders of `resources/` to LOAD_PATH.
"""
function load_resources(root_dir::String = RESOURCES_PATH) :: Nothing
  isdir(root_dir) || return nothing

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
    load_helpers(root_dir::String = HELPERS_PATH) :: Nothing

Recursively adds subfolders of `helpers/` to LOAD_PATH.
"""
function load_helpers(root_dir::String = HELPERS_PATH) :: Nothing
  isdir(root_dir) || return nothing

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
    load_configurations(root_dir::String = CONFIG_PATH, context::Module = @__MODULE__) :: Nothing

Loads (includes) the framework's configuration files into the app's module `context`.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_configurations(root_dir::String = CONFIG_PATH; context::Module = @__MODULE__) :: Nothing
  loggers_path = joinpath(root_dir, "loggers.jl")
  isfile(loggers_path) && Revise.track(context, loggers_path, define = true)

  secrets_path = joinpath(root_dir, "secrets.jl")
  isfile(secrets_path) && Revise.track(context, secrets_path, define = true)

  nothing
end


"""
    load_initializers(root_dir::String = CONFIG_PATH, context::Module = @__MODULE__) :: Nothing

Loads (includes) the framework's initializers.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_initializers(root_dir::String = CONFIG_PATH; context::Module = @__MODULE__) :: Nothing
  dir = joinpath(root_dir, "initializers")

  isdir(dir) || return nothing

  f = readdir(dir)
  for i in f
    fi = joinpath(dir, i)
    endswith(fi, ".jl") && Revise.track(context, fi, define = true)
  end

  nothing
end


"""
    load_plugins(root_dir::String = PLUGINS_PATH; context::Module = @__MODULE__) :: Nothing

Loads (includes) the framework's plugins initializers.
"""
function load_plugins(root_dir::String = PLUGINS_PATH; context::Module = @__MODULE__) :: Nothing
  isdir(root_dir) || return nothing

  for i in readdir(root_dir)
    fi = joinpath(root_dir, i)
    endswith(fi, ".jl") && Revise.track(context, fi, define = true)
  end

  nothing
end


"""
    load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME, context::Module = @__MODULE__) :: Nothing

Loads the routes file.
"""
function load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Module = @__MODULE__) :: Nothing
  isfile(routes_file) && Revise.track(context, routes_file, define = true)

  nothing
end


"""
    secret_token(; context::Module = @__MODULE__) :: String

Wrapper around /config/secrets.jl SECRET_TOKEN `const`.
Sets up the secret token used in the app for encryption and salting.
If there isn't a valid secrets file, a temporary secret token is generated for the current session only.
"""
function secret_token(; context::Module = @__MODULE__) :: String
  if isdefined(context, :SECRET_TOKEN)
    context.SECRET_TOKEN
  else
    @warn "SECRET_TOKEN not configured - please make sure that you have a valid secrets.jl file.
          You can generate a new secrets.jl file with a random SECRET_TOKEN using Genie.REPL.write_secrets_file()
          or use the included /app/config/secrets.jl.example file as a model."

    st = REPL.secret_token()
    Core.eval(@__MODULE__, Meta.parse("""const SECRET_TOKEN = "$st" """))

    st
  end
end


"""
    load(; context::Module = @__MODULE__) :: Nothing

Main entry point to loading a Genie app.
"""
function load(; context::Module = @__MODULE__) :: Nothing
  App.bootstrap(context)

  load_configurations(context = context)

  Genie.Loggers.log_path!()

  Core.eval(Genie, Meta.parse("""const SECRET_TOKEN = "$(secret_token(context = context))" """))
  Core.eval(Genie, Meta.parse("""const ASSET_FINGERPRINT = "$(App.ASSET_FINGERPRINT)" """))

  load_initializers(context = context)
  load_helpers()

  load_libs()
  load_resources()

  load_routes_definitions(context = context)

  load_plugins(context = context)

  nothing
end
