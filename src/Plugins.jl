module Plugins

using Genie, Genie.Loggers
using Pkg


const FILES_FOLDER = "files"
const PLUGINS_FOLDER = Genie.PLUGINS_PATH
const TASKS_FOLDER = Genie.TASKS_PATH
const APP_FOLDER = Genie.APP_PATH

const path_prefix = joinpath(@__DIR__, "..", FILES_FOLDER, "new_app") |> normpath |> relpath
const FOLDERS = [ joinpath(path_prefix, APP_FOLDER),
                  joinpath(path_prefix, "db"),
                  joinpath(path_prefix, "lib"),
                  joinpath(path_prefix, PLUGINS_FOLDER),
                  joinpath(path_prefix, TASKS_FOLDER) ]


function recursive_copy(path::String, dest::String)
  for (root, dirs, files) in walkdir(path)
    dest_path = joinpath(dest, FILES_FOLDER, replace(root, (path_prefix * "/")=>""))

    try
      mkdir(dest_path)
    catch ex
      log(ex, :err)
    end

    for f in files
      startswith(f, ".") || continue # only copy hidden files, especially .gitkeep
      try
        cp(joinpath(root, f), joinpath(dest_path, f))
      catch ex
        log(ex, :err)
      end
    end
  end
end


function scaffold(plugin_name::String, dest::String)
  plugin_name = replace(plugin_name, " "=>"") |> strip |> string
  dest = normpath(dest)
  ispath(dest) || mkpath(dest)

  log("Generating project file", :info)
  cd(dest)
  Pkg.generate(plugin_name)
  dest = joinpath(dest, plugin_name)

  log("Scaffolding file structure", :info)
  mkdir(joinpath(dest, "files"))

  for path in FOLDERS
    recursive_copy(path, dest)
  end

  touch(joinpath(dest, FILES_FOLDER, PLUGINS_FOLDER, lowercase(plugin_name) * ".jl"))

  log("Adding dependencies", :info)

  cd(dest)
  pkg"activate ."
  pkg"add https://github.com/genieframework/Genie.jl"

  run(`git init`)
  run(`git add .`)
  run(`git commit -am "initial commit"`)
end

end
