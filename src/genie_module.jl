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
    Core.eval(context, :(SearchLight.Generator.newresource(uppercasefirst($resource_name))))
  catch
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
  isfile(secrets_path) && Revise.includet(default_context(context), secrets_path)

  # check that the secrets_path has called Genie.secret_token!
  if isempty(Genie.secret_token(false)) # do not generate a temporary token in this check
    match_deprecated = isfile(secrets_path) ? match(r"SECRET_TOKEN\s*=\s*\"(.*)\"", readline(secrets_path)) : nothing
    if match_deprecated !== nothing # does the file use the deprecated syntax?
      Genie.secret_token!(match_deprecated.captures[1]) # resolve the issue for now
      @warn "
        $(secrets_path) is using a deprecated syntax to set the secret token.
        Call Genie.Generator.migrate_secrets_file() to resolve this warning.
      "
    end

    Genie.secret_token() # emits a warning and re-generates the token if secrets_path is not valid
  end

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
    endswith(fi, ".jl") && Revise.includet(default_context(context), fi)
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
    endswith(fi, ".jl") && Revise.includet(default_context(context), fi)
  end

  nothing
end


"""
    load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing

Loads the routes file.
"""
function load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing, additional_routes_file::String = Genie.APP_FILE_NAME) :: Nothing
  isfile(routes_file) && Revise.includet(default_context(context), routes_file)

  nothing
end


const SECRET_TOKEN = Ref{String}("") # global state

"""
    secret_token(generate_if_missing=true) :: String

Return the secret token used in the app for encryption and salting.

Usually, this token is defined through `Genie.secret_token!` in the `config/secrets.jl` file.
Here, a temporary one is generated for the current session if no other token is defined and
`generate_if_missing` is true.
"""
function secret_token(generate_if_missing::Bool = true; context::Union{Module,Nothing} = nothing)
  if context != nothing
    @warn "secret_token not context-dependent any more; the context argument is deprecated"
  end

  if isempty(SECRET_TOKEN[]) && generate_if_missing
    @warn "
          No secret token is defined through `Genie.secret_token!(\"token\")`. Such a token
          is needed to hash and to encrypt/decrypt sensitive data in Genie, including cookie
          and session data.

          If your app relies on cookies or sessions make sure you generate a valid token,
          otherwise the encrypted data will become unreadable between app restarts.

          You can resolve this issue by generating a valid `config/secrets.jl` file with a
          random token, calling `Genie.Generator.write_secrets_file()`.
          "
    secret_token!()
  end

  SECRET_TOKEN[]
end

"""
    secret_token!(value=Generator.secret_token())

Define the secret token used in the app for encryption and salting.
"""
function secret_token!(value::AbstractString = Generator.secret_token())
  SECRET_TOKEN[] = value

  value
end


"""
    default_context(context::Union{Module,Nothing})

Sets the module in which the code is loaded (the app's module)
"""
function default_context(context::Union{Module,Nothing} = nothing)
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

  Genie.Configuration.isdev() && Core.eval(context, :(__revise_mode__ = :eval))

  App.bootstrap(context)

  t = Terminals.TTYTerminal("", stdin, stdout, stderr)

  load_configurations(context = context)

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
