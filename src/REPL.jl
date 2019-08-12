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


"""
"""
function copy_fullstack_app(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", "files", "new_app"), app_path)

  nothing
end


"""
"""
function copy_microstack_app(app_path::String = ".") :: Nothing
  mkdir(app_path)

  for f in ["bin", "config", "public", "src",
            ".gitattributes", ".gitignore",
            "bootstrap.jl", "env.jl", "genie.jl", "routes.jl"]
    cp(joinpath(@__DIR__, "..", "files", "new_app", f), joinpath(app_path, f))
  end

  remove_fingerprint_initializer(app_path)

  nothing
end


"""
"""
function copy_db_support(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", "files", "new_app", "db"), joinpath(app_path, "db"))
  cp(joinpath(@__DIR__, "..", "files", "new_app", "config", "initializers", "searchlight.jl"), joinpath(app_path, "config", "initializers", "searchlight.jl"))

  nothing
end


"""
"""
function copy_mvc_support(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", "files", "new_app", "app"), joinpath(app_path, "app"))

  nothing
end


"""
Generates a valid secrets.jl file with a random SECRET_TOKEN.
"""
function write_secrets_file(app_path::String = ".") :: Nothing
  open(joinpath(app_path, Genie.CONFIG_PATH, "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  nothing
end


"""
"""
function write_app_custom_files(path::String, app_path::String) :: Nothing
  moduleinfo = FileTemplates.appmodule(path)

  open(joinpath(app_path, "src", moduleinfo[1] * ".jl"), "w") do f
    write(f, moduleinfo[2])
  end

  chmod(joinpath(app_path, "bootstrap.jl"), 0o644)

  open(joinpath(app_path, "bootstrap.jl"), "w") do f
    write(f,
    """
      cd(@__DIR__)
      using Pkg
      pkg"activate ."

      function main()
        include(joinpath("src", "$(moduleinfo[1]).jl"))
      end; main()
    """)
  end

  nothing
end


"""
"""
function install_app_dependencies(app_path::String = ".") :: Nothing
  log("Installing app dependencies")
  pkg"activate ."

  pkg"add Genie"
  pkg"add JSON"
  pkg"add Millboard"
  pkg"add Revise"

  nothing
end


"""
"""
function autostart_app(autostart::Bool = true) :: Nothing
  if autostart
    log("Starting your brand new Genie app - hang tight!", :info)
    loadapp(".", autostart = autostart)
  else
    log("Your new Genie app is ready!
        Run \njulia> Genie.loadapp() \nto load the app's environment
        and then \njulia> Genie.startup() \nto start the web server on port 8000.")
  end

  nothing
end


"""
"""
function remove_fingerprint_initializer(app_path::String = ".") :: Nothing
  rm(joinpath(app_path, "config", "initializers", "fingerprint.jl"), force = true)

  nothing
end


"""
"""
function remove_searchlight_initializer(app_path::String = ".") :: Nothing
  rm(joinpath(app_path, "config", "initializers", "searchlight.jl"), force = true)

  nothing
end


"""
    newapp(path::String = "."; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing

Scaffolds a new Genie app, setting up the file structure indicated by the various arguments.

# Arguments
- `path::String`: the name of the app and the path where to bootstrap it
- `autostart::Bool`: automatically start the app once the file structure is created
- `fullstack::Bool`: the type of app to be bootstrapped. The fullstack app includes MVC structure, DB connection code, and asset pipeline files.
- `dbsupport::Bool`: bootstrap the files needed for DB connection setup via the SearchLight ORM
- `mvcsupport::Bool`: adds the files used for Flax view templates rendering and working with resources

# Examples
```julia-repl
julia> Genie.newapp("MyGenieApp")
2019-08-06 16:54:15:INFO:Main: Done! New app created at MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Changing active directory to MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Installing app dependencies
 Resolving package versions...
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Project.toml`
  [c43c736e] + Genie v0.10.1
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Manifest.toml`

2019-08-06 16:54:27:INFO:Main: Starting your brand new Genie app - hang tight!
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

┌ Info:
│ Starting Genie in >> DEV << mode
└
[ Info: Logging to file at MyGenieApp/log/dev.log
[ Info: Ready!
2019-08-06 16:54:32:DEBUG:Main: Web Server starting at http://127.0.0.1:8000
2019-08-06 16:54:32:DEBUG:Main: Web Server running at http://127.0.0.1:8000
```
"""
function newapp(path::String = "."; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing
  app_path = abspath(path)

  fullstack ? copy_fullstack_app(app_path) : copy_microstack_app(app_path)

  dbsupport ? (fullstack || copy_db_support(app_path)) : remove_searchlight_initializer(app_path)

  mvcsupport && (fullstack || copy_mvc_support(app_path))

  write_secrets_file(app_path)

  write_app_custom_files(path, app_path)

  Sys.iswindows() ? setup_windows_bin_files(app_path) : setup_nix_bin_files(app_path)

  log("Done! New app created at $(abspath(path))", :info)

  log("Changing active directory to $app_path")
  cd(path)

  install_app_dependencies(app_path)

  autostart_app(autostart)

  nothing
end


"""
    loadapp(path::String = "."; autostart::Bool = false) :: Nothing

Loads an existing Genie app from the file system, within the current Julia REPL session.

# Arguments
- `path::String`: the path to the Genie app on the file system.
- `autostart::Bool`: automatically start the app upon loading it.

# Examples
```julia-repl
shell> tree -L 1
.
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── env.jl
├── genie.jl
├── log
├── public
├── routes.jl
└── src

5 directories, 6 files

julia> using Genie

julia> Genie.loadapp(".")
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

┌ Info:
│ Starting Genie in >> DEV << mode
└
[ Info: Logging to file at MyGenieApp/log/dev.log
```
"""
function loadapp(path::String = "."; autostart::Bool = false) :: Nothing
  Core.eval(Main, Meta.parse("using Revise"))
  Core.eval(Main, Meta.parse("""include(joinpath("$path", "bootstrap.jl"))"""))
  Core.eval(Main, Meta.parse("Revise.revise()"))
  Core.eval(Main, Meta.parse("using Genie"))

  Core.eval(Main.UserApp, Meta.parse("Revise.revise()"))
  Core.eval(Main.UserApp, Meta.parse("$autostart && Genie.startup()"))

  nothing
end


"""
"""
function setup_windows_bin_files(path::String = ".") :: Nothing
  open(joinpath(path, "bin", "repl.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- ../bootstrap.jl %*")
  end

  open(joinpath(path, "bin", "server.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- ../bootstrap.jl s %*")
  end

  nothing
end


function setup_nix_bin_files(app_path::String = ".") :: Nothing
  chmod(joinpath(app_path, "bin", "server"), 0o700)
  chmod(joinpath(app_path, "bin", "repl"), 0o700)

  nothing
end

end
