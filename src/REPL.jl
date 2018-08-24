module REPL

using Revise, SHA, Dates
using Genie, Genie.Loggers, Genie.Configuration, Genie.Generator, Genie.Tester, Genie.Util

const JULIA_PATH = joinpath(Sys.BINDIR, "julia")


"""
    secret_token() :: String

Generates a random secret token to be used for configuring the SECRET_TOKEN const.
"""
function secret_token() :: String
  sha256("$(randn()) $(Dates.now())") |> bytes2hex
end


"""
    function new_app(path = "."; db_support = false, skip_dependencies = false) :: Nothing

Creates a new Genie app at the indicated path.
"""
function new_app(path = "."; db_support = false, skip_dependencies = true, autostart = false) :: Nothing
  cp(joinpath(@__DIR__, "../", "files", "new_app"), abspath(path))

  chmod(joinpath(path, "bin", "server"), 0o700)
  chmod(joinpath(path, "bin", "repl"), 0o700)

  open(joinpath(path, "config", "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  log("Done! New app created at $(abspath(path))", :info)

  Sys.iswindows() && setup_windows_bin_files(path)

  autostart || return nothing

  log("Starting your brand new Genie app - hang tight!", :info)
  run_repl_app(path)

  nothing
end


"""
    run_repl_app() :: Nothing

Runs a new Genie REPL app within the current thread.
"""
function run_repl_app(path = ".") :: Nothing
  cd(abspath(path))

  run(`$JULIA_PATH -L $(abspath("genie.jl")) --color=yes --depwarn=no -q`)

  nothing
end


"""

"""
function setup_windows_bin_files(path = ".")
  open(joinpath(path, "bin", "repl.bat"), "w") do f
    write(f, "$JULIA_PATH -L ../genie.jl --color=yes --depwarn=no -q -- %*")
  end

  open(joinpath(path, "bin", "server.bat"), "w") do f
    write(f, "$JULIA_PATH -L ../genie.jl --color=yes --depwarn=no -q -- s %*")
  end
end


"""
    new_model(model_name::String) :: Nothing

Creates a new `model` file.
"""
function new_model(model_name::String) :: Nothing
  SearchLight.Generator.new_model(Dict{String,Any}("model:new" => model_name))
  Genie.App.load_resources()

  nothing
end


"""
    new_controller(controller_name::String) :: Nothing

Creates a new `controller` file.
"""
function new_controller(controller_name::String) :: Nothing
  Genie.Generator.new_controller(Dict{String,Any}("controller:new" => controller_name))
  Genie.App.load_resources()

  nothing
end


"""
    new_channel(channel_name::String) :: Nothing

Creates a new `channel` file.
"""
function new_channel(channel_name::String) :: Nothing
  Genie.Generator.new_channel(Dict{String,Any}("channel:new" => channel_name))
  Genie.App.load_resources()

  nothing
end


"""
    new_resource(resource_name::String) :: Nothing

Creates all the files associated with a new resource.
"""
function new_resource(resource_name::String) :: Nothing
  Genie.Generator.new_resource(Dict{String,Any}("resource:new" => resource_name))
  Genie.App.load_resources()

  nothing
end


"""
    new_migration(migration_name::String) :: Nothing

Creates a new migration file.
"""
function new_migration(migration_name::String) :: Nothing
  SearchLight.Generator.new_migration(Dict{String,Any}("migration:new" => migration_name))
end


"""
"""
function new_table_migration(migration_name::String) :: Nothing
  SearchLight.Generator.new_table_migration(Dict{String,Any}("migration:new" => migration_name))
end


"""
    new_task(task_name::String) :: Nothing

Creates a new `Task` file.
"""
function new_task(task_name::String) :: Nothing
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Genie.Toolbox.new(Dict{String,Any}("task:new" => task_name), Genie.config)
end


"""
    write_secrets_file() :: Nothing

Generates a valid secrets.jl file with a random SECRET_TOKEN.
"""
function write_secrets_file() :: Nothing
  open(joinpath(Genie.CONFIG_PATH, "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  log("Generated secrets.jl file in $(Genie.CONFIG_PATH)", :info)

  nothing
end


"""
    reload_app() :: Nothing
"""
function reload_app() :: Nothing
  log("Attempting to reload the Genie's core modules. If you get unexpected errors or things don't work as expected, simply exit this Julia session and start a new one to fully reload Genie.", :warn)

  is_dev() && Revise.revise(App)

  App.load_configurations()
  App.load_initializers()

  log("The app was reloaded.", :info)

  nothing
end

end
