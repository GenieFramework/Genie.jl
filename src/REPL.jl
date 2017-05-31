module REPL

using SHA, Logger, Configuration, Genie, Generator, Tester, Toolbox, App, Util
SEARCHLIGHT_ON && eval(:(using SearchLight, Migration))


"""
    secret_token() :: String

Generates a random secret token to be used for configuring the SECRET_TOKEN const.
"""
function secret_token() :: String
  sha256("$(randn()) $(Dates.now())") |> bytes2hex
end


"""
    new_app(path = ".") :: Void

Creates a new Genie app at the indicated path.
"""
function new_app(path = ".") :: Void
  cp(joinpath(Pkg.dir("Genie"), "files", "new_app"), abspath(path))

  chmod(joinpath(path, "bin/server"), 0o700)
  chmod(joinpath(path, "bin/repl"), 0o700)

  open(joinpath(path, "config", "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  Logger.log("Done! New app created at $(abspath(path))", :info)

  Logger.log("Starting your brand new Genie app - hang tight!", :info)
  cd(abspath(path))
  run(`bin/repl`)

  nothing
end


"""
    db_init() :: Bool

Sets up the DB tables used by Genie.
"""
function db_init() :: Bool
  SearchLight.create_migrations_table(Genie.config.db_migrations_table_name)
end


"""
    new_model(model_name::String) :: Void

Creates a new `model` file.
"""
function new_model(model_name::String) :: Void
  Generator.new_model(Dict{String,Any}("model:new" => model_name))
end


"""
    new_controller(controller_name::String) :: Void

Creates a new `controller` file.
"""
function new_controller(controller_name::String) :: Void
  Generator.new_controller(Dict{String,Any}("controller:new" => controller_name))
end


"""
    new_channel(channel_name::String) :: Void

Creates a new `channel` file.
"""
function new_channel(channel_name::String) :: Void
  Generator.new_channel(Dict{String,Any}("channel:new" => channel_name))
end


"""
    new_resource(resource_name::String) :: Void

Creates all the files associated with a new resource.
"""
function new_resource(resource_name::String) :: Void
  Generator.new_resource(Dict{String,Any}("resource:new" => resource_name), Settings())
end


"""
    new_migration(migration_name::String) :: Void

Creates a new migration file.
"""
function new_migration(migration_name::String) :: Void
  Generator.new_migration(Dict{String,Any}("migration:new" => migration_name), Settings())
end


"""
    new_task(task_name::String) :: Void

Creates a new `Task` file.
"""
function new_task(task_name::String) :: Void
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Toolbox.new(Dict{String,Any}("task:new" => task_name), Genie.config)
end


"""
    write_secrets_file() :: Void

Generates a valid secrets.jl file with a random SECRET_TOKEN.
"""
function write_secrets_file() :: Void
  open(joinpath(Genie.CONFIG_PATH, "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  Logger.log("Generated secrets.jl file in $(Genie.CONFIG_PATH)", :info)

  nothing
end


"""
    reload_app() :: Void
"""
function reload_app() :: Void
  Logger.log("Attempting to reload the Genie's core modules. If you get unexpected errors or things don't work as expected, simply exit this Julia session and start a new one to fully reload Genie.", :warn)


  reload("App")
  App.load_configurations()
  App.load_initializers()

  Logger.log("The app was reloaded.", :info)

  nothing
end

end
