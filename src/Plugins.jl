module Plugins

import Genie
import Pkg, Markdown, Logging


const FILES_FOLDER = "files"
const PLUGINS_FOLDER = Genie.config.path_plugins
const TASKS_FOLDER = Genie.config.path_tasks
const APP_FOLDER = Genie.config.path_app

const path_prefix = joinpath(@__DIR__, "..", FILES_FOLDER, "new_app") |> normpath |> relpath
const FOLDERS = [ joinpath(path_prefix, APP_FOLDER),
                  joinpath(path_prefix, "db"),
                  joinpath(path_prefix, Genie.config.path_lib),
                  joinpath(path_prefix, PLUGINS_FOLDER),
                  joinpath(path_prefix, TASKS_FOLDER),
                  joinpath(path_prefix, Genie.config.server_document_root) ]


function recursive_copy(path::String, dest::String; only_hidden = true, force = false)
  for (root, dirs, files) in walkdir(path)
    dest_path = joinpath(dest, replace(root, (path_prefix * "/")=>""))

    try
      mkdir(dest_path)
      @info "Created dir $dest_path"
    catch ex
      @error "Failed to create dir $dest_path"
    end

    for f in files
      (only_hidden && startswith(f, ".")) || continue # only copy hidden files, especially .gitkeep
      try
        cp(joinpath(root, f), joinpath(dest_path, f), force = force)
        @info "Copied $(joinpath(root, f)) to $(joinpath(dest_path, f))"
      catch ex
        @error "Failed to copy $(joinpath(root, f)) to $(joinpath(dest_path, f))"
      end
    end
  end
end


function congrats()
  message = """
  Congratulations, your plugin is ready!
  You can use this default installation function in your plugin's module:
  """
  print(message)

  Markdown.doc"""
  ```julia
  function install(dest::String; force = false) :: Nothing
    src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

    for f in readdir(src)
      isfile(f) && continue
      isdir(f) || mkpath(joinpath(src, f))

      Genie.Plugins.install(joinpath(src, f), dest, force = force)
    end

    nothing
  end
  ```
  """
end


function scaffold(plugin_name::String, dest::String = "."; force = false)
  plugin_name = replace(plugin_name, " "=>"") |> strip |> string
  dest = normpath(dest) |> abspath
  ispath(dest) || mkpath(dest)

  @info "Generating project file"
  cd(dest)
  Pkg.generate(plugin_name)
  dest = joinpath(dest, plugin_name)

  @info "Scaffolding file structure"
  mkpath(joinpath(dest, FILES_FOLDER))

  for path in FOLDERS
    recursive_copy(path, joinpath(dest, FILES_FOLDER), force = force)
  end

  initializer_path = joinpath(dest, FILES_FOLDER, PLUGINS_FOLDER, lowercase(plugin_name) * ".jl")
  @info "Creating plugin initializer at $initializer_path"
  touch(initializer_path)

  @info "Adding dependencies"

  cd(dest)
  Pkg.activate(".")
  Pkg.add(Pkg.PackageSpec(name="Genie", rev="master"))

  run(`git init`)
  run(`git add .`)
  run(`git commit -am "initial commit"`)

  congrats()
end


function install(path::String, dest::String; force = false)
  isdir(Genie.config.path_plugins) || mkpath(Genie.config.path_plugins)

  isdir(dest) || mkdir(dest)

  for (root, dirs, files) in walkdir(path)
    dest_path = joinpath(dest, split(root, "/" * FILES_FOLDER * "/")[end])

    try
      mkdir(dest_path)
      @info "Created dir $dest_path"
    catch ex
      @error "Did not create dir $dest_path"
    end

    for f in files
      try
        cp(joinpath(root, f), joinpath(dest_path, f), force = force)
        @info "Copied $(joinpath(root, f)) to $(joinpath(dest_path, f))"
      catch ex
        @error "Did not copy $(joinpath(root, f)) to $(joinpath(dest_path, f))"
      end
    end
  end
end

end
