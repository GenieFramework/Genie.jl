"""
Genie code loading functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module Loader

import Logging
import REPL, REPL.Terminals
import Revise
import Genie
import Sockets

const post_load_hooks = Function[]

### PRIVATE ###


function importenv()
  haskey(ENV, "WSPORT") && (! isempty(ENV["WSPORT"])) && (Genie.config.websockets_port = parse(Int, ENV["WSPORT"]))
  haskey(ENV, "WSEXPPORT") && (! isempty(ENV["WSEXPPORT"])) && (Genie.config.websockets_exposed_port = parse(Int, ENV["WSEXPPORT"]))
  haskey(ENV, "WSEXPHOST") && (! isempty(ENV["WSEXPHOST"])) && (Genie.config.websockets_exposed_host = ENV["WSEXPHOST"])
  haskey(ENV, "WSBASEPATH") && (Genie.config.websockets_base_path = ENV["WSBASEPATH"])
  haskey(ENV, "BASEPATH") && (Genie.config.base_path = ENV["BASEPATH"])

  nothing
end


function loadenv(; context)
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
  bootstrap(context)

  haskey(ENV, "GENIE_HOST") && (! isempty(ENV["GENIE_HOST"])) && (Genie.config.server_host = ENV["GENIE_HOST"])
  haskey(ENV, "GENIE_HOST") || (ENV["GENIE_HOST"] = Genie.config.server_host)

  haskey(ENV, "PORT") && (! isempty(ENV["PORT"])) && (Genie.config.server_port = parse(Int, ENV["PORT"]))
  haskey(ENV, "PORT") || (ENV["PORT"] = Genie.config.server_port)

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
function bootstrap(context::Union{Module,Nothing} = default_context(context)) :: Nothing
  ENV_FILE_NAME = "env.jl"
  GLOBAL_ENV_FILE_NAME = "global.jl"

  haskey(ENV, "GENIE_ENV") && (Genie.config.app_env = ENV["GENIE_ENV"])

  isfile(joinpath(Genie.config.path_env, GLOBAL_ENV_FILE_NAME)) && Base.include(context, joinpath(Genie.config.path_env, GLOBAL_ENV_FILE_NAME))
  isfile(joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl")) && Base.include(context, joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl"))
  Genie.config.app_env = ENV["GENIE_ENV"] # ENV might have changed
  importenv()

  get!(ENV, "GENIE_BANNER", "true") |> strip |> lowercase != "false" && print_banner()

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
  printstyled("| Docs     https://genieframework.com/docs\n", color = :light_black, bold = true)
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
  isfile(app_file) && Revise.includet(default_context(context), app_file)

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
                  autoload_ignore_file::String = Genie.config.autoload_ignore_file) :: Nothing
  isdir(root_dir) || return nothing

  validinclude(fi)::Bool = endswith(fi, ".jl") && match(namematch, fi) !== nothing &&
                            ((skipmatch !== nothing && match(skipmatch, fi) === nothing) || skipmatch === nothing)

  for i in sort_load_order(root_dir, readdir(root_dir))
    isfile(joinpath(root_dir, autoload_ignore_file)) && continue

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
  excludedfiles = map(elem -> elem[1] == '-' ? replace(pop!(autoloadorder), "-" => "") : nothing , autoloadorder)
  filter!(elem -> elem !== nothing, excludedfiles)
  lsdirexcluded = filter(elem -> !(elem in excludedfiles), lsdir)
  loadorder = issubset(unique(autoloadorder), unique(lsdirexcluded)) ? autoloadorder : throw(ArgumentError("Autoload file contains files not in directory"))
  append!(loadorder, Base.symdiff(loadorder, unique(lsdirexcluded)))
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

end