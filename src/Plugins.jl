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


function recursive_copy(path::String, dest::String; only_hidden = true, force = false)
  for (root, dirs, files) in walkdir(path)
    dest_path = joinpath(dest, replace(root, (path_prefix * "/")=>""))

    try
      mkdir(dest_path)
      log("Created dir $dest_path", :info)
    catch ex
      log("Failed to create dir $dest_path", :err)
    end

    for f in files
      (only_hidden && startswith(f, ".")) || continue # only copy hidden files, especially .gitkeep
      try
        cp(joinpath(root, f), joinpath(dest_path, f), force = force)
        log("Copied $(joinpath(root, f)) to $(joinpath(dest_path, f))", :info)
      catch ex
        log("Failed to copy $(joinpath(root, f)) to $(joinpath(dest_path, f))", :err)
      end
    end
  end
end


function scaffold(plugin_name::String, dest::String; force = false)
  plugin_name = replace(plugin_name, " "=>"") |> strip |> string
  dest = normpath(dest)
  ispath(dest) || mkpath(dest)

  log("Generating project file", :info)
  cd(dest)
  Pkg.generate(plugin_name)
  dest = joinpath(dest, plugin_name)

  log("Scaffolding file structure", :info)
  mkdir(joinpath(dest, FILES_FOLDER))

  for path in FOLDERS
    recursive_copy(path, joinpath(dest, FILES_FOLDER), force = force)
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


function install(path::String, dest::String; force = false)
  for (root, dirs, files) in walkdir(path)
    dest_path = joinpath(dest, split(root, "/" * FILES_FOLDER * "/")[end])

    try
      mkdir(dest_path)
      log("Created dir $dest_path", :info)
    catch ex
      log("Failed to create dir $dest_path", :err)
    end

    for f in files
      try
        cp(joinpath(root, f), joinpath(dest_path, f), force = force)
        log("Copied $(joinpath(root, f)) to $(joinpath(dest_path, f))", :info)
      catch ex
        log("Failed to copy $(joinpath(root, f)) to $(joinpath(dest_path, f))", :err)
      end
    end
  end
end

end
