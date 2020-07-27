### THIS IS LOADED INTO the Genie module


import Logging
import REPL, REPL.Terminals


### PUBLIC ###


"""
    newcontroller(controller_name::Union{String,Symbol}) :: Nothing

Creates a new `controller` file. If `pluralize` is `false`, the name of the controller is not automatically pluralized.
"""
function newcontroller(controller_name::Union{String,Symbol}; path::Union{String,Nothing} = nothing, pluralize::Bool = true) :: Nothing
  Generator.newcontroller(string(controller_name), path = path, pluralize = pluralize)
  load_resources()

  nothing
end


"""
    newresource(resource_name::Union{String,Symbol}; pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing

Creates all the files associated with a new resource.
If `pluralize` is `false`, the name of the resource is not automatically pluralized.
"""
function newresource(resource_name::Union{String,Symbol}; path::String = ".", pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  Generator.newresource(string(resource_name), path = path, pluralize = pluralize)

  try
    pluralize || error("SearchLight resources need to be pluralized")
    Core.eval(context, :(SearchLight.Generator.newresource(uppercasefirst($resource_name)))) # SearchLight resources don't work on singular
  catch ex
    @error ex
    @warn "Skipping SearchLight"
  end

  load_resources()

  nothing
end


"""
    newtask(task_name::Union{String,Symbol}) :: Nothing

Creates a new Genie `Task` file.
"""
function newtask(task_name::Union{String,Symbol}) :: Nothing
  task_name = string(task_name)
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Toolbox.new(task_name)

  nothing
end


### PRIVATE ###


"""
    load_libs(root_dir::String = Genie.config.path_lib) :: Nothing

Recursively adds subfolders of `lib/` to LOAD_PATH.
The `lib/` folder, if present, is designed to host user code in the form of .jl files.
This function loads user code into the Genie app.
"""
function load_libs(root_dir::String = Genie.config.path_lib) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  @async for (root, dirs, files) in walkdir(root_dir)
    Threads.@threads for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, p)
    end
  end

  nothing
end


"""
    load_resources(root_dir::String = Genie.config.path_resources) :: Nothing

Recursively adds subfolders of `resources/` to LOAD_PATH.
"""
function load_resources(root_dir::String = Genie.config.path_resources) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  @async for (root, dirs, files) in walkdir(root_dir)
    Threads.@threads for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end


"""
    load_helpers(root_dir::String = Genie.config.path_helpers) :: Nothing

Recursively adds subfolders of `helpers/` to LOAD_PATH.
"""
function load_helpers(root_dir::String = Genie.config.path_helpers) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  @async for (root, dirs, files) in walkdir(root_dir)
    Threads.@threads for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end


"""
    load_configurations(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's configuration files into the app's module `context`.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_configurations(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing
  secrets_path = joinpath(root_dir, Genie.SECRETS_FILE_NAME)
  isfile(secrets_path) && Revise.track(default_context(context), secrets_path, define = true)

  nothing
end


"""
    load_initializers(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's initializers.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_initializers(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing
  dir = joinpath(root_dir, Genie.config.initializers_folder)

  isdir(dir) || return nothing

  Threads.@threads for i in readdir(dir)
    fi = joinpath(dir, i)
    endswith(fi, ".jl") && Revise.track(default_context(context), fi, define = true)
  end

  nothing
end


"""
    load_plugins(root_dir::String = Genie.config.path_plugins; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's plugins initializers.
"""
function load_plugins(root_dir::String = Genie.config.path_plugins; context::Union{Module,Nothing} = nothing) :: Nothing
  isdir(root_dir) || return nothing

  Threads.@threads for i in readdir(root_dir)
    fi = joinpath(root_dir, i)
    endswith(fi, ".jl") && Revise.track(default_context(context), fi, define = true)
  end

  nothing
end


"""
    load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing

Loads the routes file.
"""
function load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing, additional_routes_file::String = Genie.APP_FILE_NAME) :: Nothing
  isfile(routes_file) && Revise.track(default_context(context), routes_file, define = true)

  nothing
end


"""
    secret_token(; context::Union{Module,Nothing} = nothing) :: String

Wrapper around /config/secrets.jl SECRET_TOKEN `const`.
Sets up the secret token used in the app for encryption and salting.
If there isn't a valid secrets file, a temporary secret token is generated for the current session only.
"""
function secret_token(; context::Union{Module,Nothing} = nothing) :: String
  context = default_context(context)

  if isdefined(context, :SECRET_TOKEN) && ! isempty(context.SECRET_TOKEN)
    context.SECRET_TOKEN
  else
    @warn "
          SECRET_TOKEN not configured - please make sure that you have a valid secrets.jl file.
          You can generate a new secrets.jl file with a random SECRET_TOKEN using Genie.Generator.write_secrets_file()
          or use the included /app/config/secrets.jl.example file as a model.

          SECRET_TOKEN is used for hashing and encrypting/decrypting sensitive data in Genie.
          I'm now setting up a random SECRET_TOKEN which will be used for this session only.
          Data that is encoded with this SECRET_TOKEN will potentially be lost
          upon restarting the application (like for example the HTTP sessions data).
          "

    SECRET_TOKEN = Generator.secret_token()
  end
end


"""
    default_context(context::Union{Module,Nothing})

Sets the module in which the code is loaded (the app's module)
"""
function default_context(context::Union{Module,Nothing})
  try
    context === nothing ? Main.UserApp : context
  catch ex
    @error ex
    @__MODULE__
  end
end


"""
    load(; context::Union{Module,Nothing} = nothing) :: Nothing

Main entry point to loading a Genie app.
"""
function load(; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  App.bootstrap(context)

  t = Terminals.TTYTerminal("", stdin, stdout, stderr)

  load_configurations(context = context)

  global SECRET_TOKEN = secret_token(context = context)
  global ASSET_FINGERPRINT = App.ASSET_FINGERPRINT

  replprint("initializers", t, clearline = 0, prefix = "Loading ")
  load_initializers(context = context)

  replprint("helpers", t, prefix = "Loading ")
  load_helpers()

  replprint("lib", t, prefix = "Loading ")
  load_libs()

  replprint("resources", t, prefix = "Loading ")
  load_resources()

  replprint("plugins", t, prefix = "Loading ")
  load_plugins(context = context)

  replprint("routes", t, prefix = "Loading ")
  load_routes_definitions(context = context)

  replprint("\nReady! \n", t, clearline = 2, color = :green, bold = :true)
  println()

  nothing
end


"""
    replprint(output::String, terminal;
                    newline::Int = 0, clearline::Int = 1, color::Symbol = :white, bold::Bool = false, sleep_time::Float64 = 0.2,
                    prefix::String = "", prefix_color::Symbol = :green, prefix_bold::Bool = true)

Prints app loading progress to the console.
"""
function replprint(output::String, terminal;
                    newline::Int = 0, clearline::Int = 1, color::Symbol = :white, bold::Bool = false, sleep_time::Float64 = 0.2,
                    prefix::String = "", prefix_color::Symbol = :green, prefix_bold::Bool = true)
  if clearline > 0
    for i in 1:(clearline+1)
      REPL.Terminals.clear_line(terminal)
    end
  end

  isempty(prefix) || printstyled(prefix, color = prefix_color, bold = prefix_bold)
  printstyled(output, color = color, bold = bold)

  if newline > 0
    for i in 1:newline
      println()
    end
  end

  sleep(sleep_time)
end