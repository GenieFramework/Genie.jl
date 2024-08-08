"""
Genie code loading functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module Loader

import Logging
import REPL, REPL.Terminals
import Revise
import Genie
import Sockets

using DotEnv

const post_load_hooks = Function[]

export @using

### PRIVATE ###


function importenv()
  haskey(ENV, "WSPORT") && (! isempty(ENV["WSPORT"])) && (Genie.config.websockets_port = parse(Int, ENV["WSPORT"]))
  haskey(ENV, "WSEXPPORT") && (! isempty(ENV["WSEXPPORT"])) && (Genie.config.websockets_exposed_port = parse(Int, ENV["WSEXPPORT"]))
  haskey(ENV, "WSEXPHOST") && (! isempty(ENV["WSEXPHOST"])) && (Genie.config.websockets_exposed_host = ENV["WSEXPHOST"])
  haskey(ENV, "WSBASEPATH") && (Genie.config.websockets_base_path = ENV["WSBASEPATH"])
  haskey(ENV, "BASEPATH") && (Genie.config.base_path = ENV["BASEPATH"])

  nothing
end


function loadenv(; context) :: Union{Sockets.TCPServer,Nothing}
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
  bootstrap(context)

  haskey(ENV, "GENIE_HOST") && (! isempty(ENV["GENIE_HOST"])) && (Genie.config.server_host = ENV["GENIE_HOST"])
  haskey(ENV, "GENIE_HOST") || (ENV["GENIE_HOST"] = Genie.config.server_host)

  haskey(ENV, "PORT") && (! isempty(ENV["PORT"])) && (Genie.config.server_port = parse(Int, ENV["PORT"]))
  haskey(ENV, "PORT") || (ENV["PORT"] = Genie.config.server_port)

  haskey(ENV, "WSPORT") && (! isempty(ENV["WSPORT"])) && (Genie.config.websockets_port = parse(Int, ENV["WSPORT"]))

  ### EARLY BIND TO PORT FOR HOSTS WITH TIMEOUT ###
  EARLYBINDING = if haskey(ENV, "EARLYBIND") && strip(lowercase(ENV["EARLYBIND"])) == "true"
    @info "Binding to host $(ENV["GENIE_HOST"]) and port $(ENV["PORT"]) \n"
    try
      Sockets.listen(parse(Sockets.IPAddr, ENV["GENIE_HOST"]), parse(Int, ENV["PORT"]))
    catch ex
      @error ex

      @warn "Failed binding! \n"
      nothing
    end
  else
    nothing
  end
end


"""
    bootstrap(context::Union{Module,Nothing} = nothing) :: Nothing

Kickstarts the loading of a Genie app by loading the environment settings.
"""
function bootstrap(context::Union{Module,Nothing} = default_context(context); show_banner::Bool = true) :: Nothing
  ENV_FILE_NAME = "env.jl"
  GLOBAL_ENV_FILE_NAME = "global.jl"

  load_dotenv()

  if haskey(ENV, "GENIE_ENV")
    Genie.config.app_env = ENV["GENIE_ENV"]
  else
    ENV["GENIE_ENV"] = Genie.config.app_env = "dev"
  end

  isfile(joinpath(Genie.config.path_env, GLOBAL_ENV_FILE_NAME)) && Base.include(context, joinpath(Genie.config.path_env, GLOBAL_ENV_FILE_NAME))
  isfile(joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl")) && Base.include(context, joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl"))
  Genie.config.app_env = ENV["GENIE_ENV"] # ENV might have changed
  importenv()

  get!(ENV, "GENIE_BANNER", "true") |> strip |> lowercase != "false" && show_banner && print_banner()

  nothing
end


"""
Loads .env file if present
"""
function load_dotenv()
  if isfile(Genie.config.env_file)
    @static if VersionNumber(Genie.Util.package_version(DotEnv)) >= v"1.0"
      DotEnv.load!(Genie.config.env_file; override = true)
    else
      DotEnv.config(; path = Genie.config.env_file, override = true)
    end
  end

  nothing
end


function print_banner()
  printstyled("""


 ██████╗ ███████╗███╗   ██╗██╗███████╗    ███████╗
██╔════╝ ██╔════╝████╗  ██║██║██╔════╝    ██╔════╝
██║  ███╗█████╗  ██╔██╗ ██║██║█████╗      ███████╗
██║   ██║██╔══╝  ██║╚██╗██║██║██╔══╝      ╚════██║
╚██████╔╝███████╗██║ ╚████║██║███████╗    ███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚══════╝    ╚══════╝

""", color = :light_black, bold = true)

  printstyled("| Website  https://genieframework.com\n", color = :light_black, bold = true)
  printstyled("| GitHub   https://github.com/genieframework\n", color = :light_black, bold = true)
  printstyled("| Docs     https://learn.genieframework.com\n", color = :light_black, bold = true)
  printstyled("| Discord  https://discord.com/invite/9zyZbD6J7H\n", color = :light_black, bold = true)
  printstyled("| Twitter  https://twitter.com/essenciary\n\n", color = :light_black, bold = true)
  printstyled("Active env: $(ENV["GENIE_ENV"] |> uppercase)\n\n", color = :light_blue, bold = true)

  nothing
end


"""
    load_libs(root_dir::String = Genie.config.path_lib) :: Nothing

Recursively includes files from `lib/` and subfolders.
The `lib/` folder, if present, is designed to host user code in the form of .jl files.
"""
function load_libs(root_dir::String = Genie.config.path_lib; context::Union{Module,Nothing} = nothing) :: Nothing
  autoload(root_dir; context)
end


"""
    load_resources(root_dir::String = Genie.config.path_resources) :: Nothing

Automatically recursively includes files from `resources/` and subfolders.
"""
function load_resources(root_dir::String = Genie.config.path_resources;
                        context::Union{Module,Nothing} = nothing) :: Nothing
  skpdr = ["views"]
  @debug "Auto loading validators"
  autoload(root_dir; context, skipdirs = skpdr, namematch = r"Validator\.jl$") # validators first, used by models

  @debug "Auto loading models"
  autoload(root_dir; context, skipdirs = skpdr, skipmatch = r"Controller\.jl$|Validator\.jl$") # next models

  @debug "Auto loading controllers"
  autoload(root_dir; context, skipdirs = skpdr, namematch = r"Controller\.jl$") # finally controllers
end


"""
    load_helpers(root_dir::String = Genie.config.path_helpers) :: Nothing

Automatically recursively includes files from `helpers/` and subfolders.
"""
function load_helpers(root_dir::String = Genie.config.path_helpers; context::Union{Module,Nothing} = nothing) :: Nothing
  autoload(root_dir; context)
end


"""
    load_initializers(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing

Automatically recursively includes files from `initializers/` and subfolders.
"""
function load_initializers(root_dir::String = Genie.config.path_initializers; context::Union{Module,Nothing} = nothing) :: Nothing
  autoload(root_dir; context)
end


"""
    load_plugins(root_dir::String = Genie.config.path_plugins; context::Union{Module,Nothing} = nothing) :: Nothing

Automatically recursively includes files from `plugins/` and subfolders.
"""
function load_plugins(root_dir::String = Genie.config.path_plugins; context::Union{Module,Nothing} = nothing) :: Nothing
  autoload(root_dir; context)
end


"""
    load_routes(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing

Loads the routes file.
"""
function load_routes(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing
  isfile(routes_file) && Revise.includet(default_context(context), routes_file)

  nothing
end


"""
    load_app(app_file::String = Genie.APP_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing

Loads the app file (`app.jl` can be used for single file apps, instead of `routes.jl`).
"""
function load_app(app_file::String = Genie.APP_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing
  isfile(app_file) && Revise.includet(default_context(context), abspath(app_file))

  nothing
end


"""
    autoload

Automatically and recursively includes files from the indicated `root_dir` into the indicated `context` module,
skipping directories from `dir`.
The files are set up with `Revise` to be automatically reloaded when changed (in dev environment).
"""
function autoload(root_dir::String = Genie.config.path_lib;
                  context::Union{Module,Nothing} = nothing,
                  skipdirs::Vector{String} = String[],
                  namematch::Regex = r".*",
                  skipmatch::Union{Regex,Nothing} = nothing,
                  autoload_ignore_file::String = Genie.config.autoload_ignore_file,
                  autoload_file::String = Genie.config.autoload_file) :: Nothing
  isdir(root_dir) || return nothing

  validinclude(fi)::Bool = endswith(fi, ".jl") && match(namematch, fi) !== nothing &&
                            ((skipmatch !== nothing && match(skipmatch, fi) === nothing) || skipmatch === nothing)

  for i in sort_load_order(root_dir, readdir(root_dir))
    (isfile(joinpath(root_dir, autoload_ignore_file)) || i == autoload_file ) && continue

    fi = joinpath(root_dir, i)
    @debug "Checking $fi"
    if validinclude(fi)
      @debug "Auto loading file: $fi"
      Revise.includet(default_context(context), fi)
    end
  end

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      in(dir, skipdirs) && continue

      p = joinpath(root, dir)
      for i in readdir(p)
        isfile(joinpath(p, autoload_ignore_file)) && continue

        fi = joinpath(p, i)
        @debug "Checking $fi"
        if validinclude(fi)
          @debug "Auto loading file: $fi"
          Revise.includet(default_context(context), fi)
        end
      end
    end
  end

  nothing
end


function autoload(dirs::Vector{String}; kwargs...)
  for d in dirs
    autoload(d; kwargs...)
  end
end


function autoload(dirs...; kwargs...)
  autoload([dirs...]; kwargs...)
end

"""
    sort_load_order(root_dir::String, files::Vector{String}) :: Vector{String}

Returns a sorted list of files based on `.autoload` file. If `.autoload` file is a not present in `rootdir` return original output of `readdir()`.
"""
function sort_load_order(rootdir, lsdir::Vector{String})
  autoloadfilepath = isfile(joinpath(pwd(), rootdir, Genie.config.autoload_file)) ? joinpath(pwd(), rootdir, Genie.config.autoload_file) : return lsdir
  autoloadorder = open(f -> ([line for line in eachline(f)]), autoloadfilepath)
  fn_loadorder = []

  for file in autoloadorder
    if file in lsdir
      push!(fn_loadorder, file)
      filter!(f -> f != file, lsdir)
    elseif startswith(file, '-') && file[2:end] ∈ lsdir
      filter!(f -> f != file[2:end], lsdir)
      continue
    else
      continue
    end
  end

  append!(fn_loadorder, lsdir)
end

"""
    load(; context::Union{Module,Nothing} = nothing) :: Nothing

Main entry point to loading a Genie app.
"""
function load(; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  Genie.Configuration.isdev() && Core.eval(context, :(__revise_mode__ = :eval))

  t = Terminals.TTYTerminal("", stdin, stdout, stderr)

  for i in Genie.config.autoload
    f = getproperty(@__MODULE__, Symbol("load_$i"))
    Genie.Repl.replprint(string(i), t; prefix = "Loading ", clearline = 3, sleep_time = 0.0)
    Base.@invokelatest f(; context)
    Genie.Repl.replprint("$i ✅", t; prefix = "Loading ", clearline = 3, color = :green, sleep_time = 0.1)
  end

  if ! isempty(post_load_hooks)
    Genie.Repl.replprint("Running post load hooks ✅", t; clearline = 3, color = :green, sleep_time = 0.1)
    for f in unique(post_load_hooks)
      f |> Base.invokelatest
    end
  end

  Genie.Repl.replprint("\nReady! \n", t; clearline = 1, color = :green, bold = :true)
  println()

  nothing
end


"""
    default_context(context::Union{Module,Nothing})

Sets the module in which the code is loaded (the app's module)
"""
function default_context(context::Union{Module,Nothing} = nothing)
  try
    userapp = isdefined(Main, :UserApp) ? Main.UserApp : @__MODULE__
    context === nothing ? userapp : context
  catch ex
    @error ex
    @__MODULE__
  end
end


function expr_to_path(expr::Union{Expr, Symbol, String})::String
  path = String[]
  while expr isa Expr && expr.head == :call && expr.args[1] ∈ (:\, :/)
      push!(path, String(expr.args[3]))
      expr = expr.args[2]
  end
  push!(path, String(expr))
  return join(reverse(path), '/')
end

function _findpackage(package::String)
  orig_package = package
  path, package = splitdir(package)
  validpath = if path != ""
      loadpath = copy(LOAD_PATH)
      empty!(LOAD_PATH)
      push!(LOAD_PATH, path)
      true
  else
      false
  end
  
  p = Base.find_package(package)
  if p === nothing
      if isdir(orig_package)
          pushfirst!(LOAD_PATH, orig_package)
          p = Base.find_package(package)
          popfirst!(LOAD_PATH)
      end
  end

  if validpath
      empty!(LOAD_PATH)
      append!(LOAD_PATH, loadpath)
  end

  p === nothing && return
  path, package = splitdir(p)
  package = splitext(package)[1]

  basedir, parentdir = splitdir(path)
  # if it is a package structure prepend parent directory of the package as LOAD_PATH to path
  if parentdir == "src" && basename(basedir) == package
      path = "$(dirname(basedir));$path"
  end
  
  path, package
end

"""
    @using(package_path)

Macro to simplify loading of modules taking advantage of precompilation.
When called from Main it temporarilty adds the path to LOAD_PATH and loads the module via `using`
When called from a different module it includes the module file and uses `using .MyModule`

`package_path` can be used in several ways
- as a path to a directory containing a module file of the same name
    e.g '@using models/MyApp' to load 'models/MyApp/MyApp.jl'
- as a path to a module (without extension '.jl')
    e.g. '@using models/MyApp' to load models/MyApp.jl'
- as a path to a package directory containing a 'src' directory and module file therein
    e.g. '@using models/MyApp' to load 'models/MyApp/src/MyApp.jl'

### Examples

```julia
@using models/MyApp

@using StippleDemos/Vue3/Calendars
```
or explicitly
```julia
@using StippleDemos/Vue3/Calendars/Calendars
```
Note, directories containing special characters like colon (`':'`) or space (`' '`)
need to be escaped by double quotes.
```julia
@using "C:/Program Files/Julia/models/Calendars"

# or
@using "C:/Program Files"/Julia/models/Calendars
```

Caveat: Due to precompilation it is not possible to supply variables to the macro.
Calls need to supply explicit paths.
"""
macro _using(package)
  # determine whether @using is called from Main or a different module
  is_submodule = __module__ != Base.Main
  package = expr_to_path(package)
  fp = _findpackage(package)
  if fp === nothing
      @warn "package $package not found"
      return nothing
  end
  path, package_name = fp
  package_symbol = Symbol(package_name)

  if is_submodule
    # if called from submodule add module via `include()` and, `using .MyModule`
    quote
      include(joinpath($path, "$($package_name).jl"))
      using .$(package_symbol)
    end |> esc
  else
    # if called from Main add module via setting LOAD_PATH and `using MyModule`
    quote
      println("hi $($package_name)")

      let pp = split($path, ';')
        for p in reverse(pp)
          pushfirst!(LOAD_PATH, p)
        end
      
        @debug "using $($package_name) (from '$($path)')"
        try
          using $package_symbol 
        catch e
          error(e)
        finally
            for _ in pp 
              popfirst!(LOAD_PATH)
            end
        end
      end
      nothing
    end
  end
end

const var"@using" = var"@_using"

end