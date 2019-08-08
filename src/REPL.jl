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

Creates a new Genie app at the indicated path.
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
const new_app = newapp


"""
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
