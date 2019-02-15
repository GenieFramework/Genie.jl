module REPL

using Revise, SHA, Dates, Pkg
using Genie, Genie.Loggers, Genie.Configuration, Genie.Generator, Genie.Tester, Genie.Util, Genie.FileTemplates

const JULIA_PATH = joinpath(Sys.BINDIR, "julia")


"""
    secret_token() :: String

Generates a random secret token to be used for configuring the SECRET_TOKEN const.
"""
function secret_token() :: String
  sha256("$(randn()) $(Dates.now())") |> bytes2hex
end
const secrettoken = secret_token


"""
    function new_app(path = "."; db_support = false, skip_dependencies = false) :: Nothing

Creates a new Genie app at the indicated path.
"""
function new_app(path::String; db_support = false, autostart = true) :: Nothing
  cp(joinpath(@__DIR__, "../", "files", "new_app"), abspath(path))

  chmod(joinpath(path, "bin", "server"), 0o700)
  chmod(joinpath(path, "bin", "repl"), 0o700)

  open(joinpath(path, "config", "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  moduleinfo = FileTemplates.appmodule(path)
  open(joinpath(path, moduleinfo[1] * ".jl"), "w") do f
    write(f, moduleinfo[2])
  end
  open(joinpath(path, "bootstrap.jl"), "w") do f
    write(f, """include("$(moduleinfo[1]).jl")""")
  end

  log("Done! New app created at $(abspath(path))", :info)

  Sys.iswindows() && setup_windows_bin_files(path)

  log("Changing active directory to $path")
  cd(path)

  log("Installing app dependencies")
  pkg"activate ."
  pkg"instantiate"

  if autostart
    log("Starting your brand new Genie app - hang tight!", :info)
    load_app(".", autostart = autostart)
  else
    log("Your new Genie app is ready!
        Run \njulia> Genie.REPL.load_app() \nto load the app's environment
        and then \njulia> Genie.AppServer.startup() \nto start the web server on port 8000.")
  end

  nothing
end
const newapp = new_app


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
function load_app(path = "."; autostart = false) :: Nothing
  Core.eval(Main, Meta.parse("using Revise"))
  Core.eval(Main, Meta.parse("""include(joinpath("$path", "bootstrap.jl"))"""))
  Core.eval(Main, Meta.parse("Revise.revise()"))
  Core.eval(Main, Meta.parse("using Genie"))

  Core.eval(Main.UserApp, Meta.parse("Revise.revise()"))
  Core.eval(Main.UserApp, Meta.parse("$autostart && Genie.AppServer.startup()"))

  nothing
end
const loadapp = load_app


"""

"""
function setup_windows_bin_files(path = ".")
  open(joinpath(path, "bin", "repl.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- bootstrap.jl %*")
  end

  open(joinpath(path, "bin", "server.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- bootstrap.jl s %*")
  end
end


"""
    new_model(model_name::String) :: Nothing

Creates a new `model` file.
"""
function new_model(model_name::String) :: Nothing
  SearchLight.Generator.new_model(Dict{String,Any}("model:new" => model_name))
  Main.UserApp.load_resources()

  nothing
end
const newmodel = new_model


"""
    new_controller(controller_name::String) :: Nothing

Creates a new `controller` file.
"""
function new_controller(controller_name::String) :: Nothing
  Genie.Generator.new_controller(Dict{String,Any}("controller:new" => controller_name))
  Main.UserApp.load_resources()

  nothing
end
const newcontroller = new_controller


"""
    new_channel(channel_name::String) :: Nothing

Creates a new `channel` file.
"""
function new_channel(channel_name::String) :: Nothing
  Genie.Generator.new_channel(Dict{String,Any}("channel:new" => channel_name))
  Main.UserApp.load_resources()

  nothing
end


"""
    new_resource(resource_name::String) :: Nothing

Creates all the files associated with a new resource.
"""
function new_resource(resource_name::String) :: Nothing
  Genie.Generator.new_resource(Dict{String,Any}("resource:new" => resource_name))
  try
    Main.UserApp.load_resources()
  catch ex
    log("Not in app, skipping autoload", :warn)
  end

  nothing
end
const newchannel = new_channel


"""
    new_migration(migration_name::String) :: Nothing

Creates a new migration file.
"""
function new_migration(migration_name::String) :: Nothing
  SearchLight.Generator.new_migration(Dict{String,Any}("migration:new" => migration_name))
end
const newmigration = new_migration


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
const newtask = new_task


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

  Main.UserApp.load_configurations()
  Main.UserApp.load_initializers()

  log("The app was reloaded.", :info)

  nothing
end
const reloadapp = reload_app


"""
    load_resources(dir = Genie.RESOURCES_PATH) :: Nothing

Recursively adds subfolders of resources to LOAD_PATH.
"""
function load_resources(root_dir) :: Nothing
  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end
const loadresources = load_resources

end
