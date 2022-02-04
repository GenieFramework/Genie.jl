"""
Loads dependencies and bootstraps a Genie app. Exposes core Genie functionality.
"""
module Genie

import Revise

push!(LOAD_PATH, @__DIR__)

import Inflector

include("Configuration.jl")
using .Configuration

const config = Configuration.Settings()

include("constants.jl")

import Sockets
import Logging

using Reexport

include(joinpath(@__DIR__, "genie_types.jl"))

include("HTTPUtils.jl")
include("Exceptions.jl")
include("App.jl")
include("genie_module.jl")
include("Util.jl")
include("FileTemplates.jl")
include("Toolbox.jl")
include("Generator.jl")
include("Encryption.jl")
include("Cookies.jl")
include("Input.jl")
include("Router.jl")
include("Renderer.jl")
include("WebChannels.jl")
include("WebThreads.jl")
include("Headers.jl")
include("Assets.jl")
include("AppServer.jl")
include("Commands.jl")
include("Responses.jl")
include("Requests.jl")
include("Flash.jl")
include("Plugins.jl")
include("Deploy.jl")

# === #
# EXTRAS #

include("Cache.jl")
config.cache_storage == :File && include("cache_adapters/FileCache.jl")

include("Sessions.jl")

export serve, up, down, loadapp, genie, bootstrap, isrunning
@reexport using .Router

const assets_config = Genie.Assets.assets_config

"""
    serve(path::String = pwd(), params...; kwparams...)

Serves a folder of static files located at `path`. Allows Genie to be used as a static files web server.
The `params` and `kwparams` arguments are forwarded to `Genie.startup()`.

# Arguments
- `path::String`: the folder of static files to be served by the server
- `params`: additional arguments which are passed to `Genie.startup` to control the web server
- `kwparams`: additional keyword arguments which are passed to `Genie.startup` to control the web server

# Examples
```julia-repl
julia> Genie.serve("public", 8888, async = false, verbose = true)
[ Info: Ready!
2019-08-06 16:39:20:DEBUG:Main: Web Server starting at http://127.0.0.1:8888
[ Info: Listening on: 127.0.0.1:8888
[ Info: Accept (1):  🔗    0↑     0↓    1s 127.0.0.1:8888:8888 ≣16
```
"""
function serve(path::String = pwd(), params...; kwparams...)
  cd(path)
  path = ""

  Router.route("/") do
    Router.serve_static_file(path, root = path)
  end
  Router.route(".*") do
    Router.serve_static_file(Router.params(:REQUEST).target, root = path)
  end

  up(params...; kwparams...)
end


### NOT EXPORTED ###


"""
    newapp(path::String = "."; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing

Scaffolds a new Genie app, setting up the file structure indicated by the various arguments.

# Arguments
- `path::String`: the name of the app and the path where to bootstrap it
- `autostart::Bool`: automatically start the app once the file structure is created
- `fullstack::Bool`: the type of app to be bootstrapped. The fullstack app includes MVC structure, DB connection code, and asset pipeline files.
- `dbsupport::Bool`: bootstrap the files needed for DB connection setup via the SearchLight ORM
- `mvcsupport::Bool`: adds the files used for HTML+Julia view templates rendering and working with resources

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
const newapp  = Generator.newapp
const new     = Generator.newapp

const newapp_webservice = Generator.newapp_webservice
const newapp_mvc = Generator.newapp_mvc
const newapp_fullstack = Generator.newapp_fullstack

const newappwebservice = Generator.newapp_webservice
const newappmvc = Generator.newapp_mvc
const newappfullstack = Generator.newapp_fullstack


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
function loadapp(path::String = "."; autostart::Bool = false, dbadapter = Union{Nothing,Symbol,String} = nothing) :: Nothing
  if ! isnothing(dbadapter) && dbadapter != "nothing"
    Core.eval(Main, Meta.parse("using SearchLight"))
    Core.eval(Main, Meta.parse("using SearchLight$dbadapter"))

    Core.eval(Main, Meta.parse("Genie.Generator.@write_db_config()"))
  end

  Core.eval(Main, quote
      include(joinpath($path, $(Genie.BOOTSTRAP_FILE_NAME)))
  end)

  autostart && (Core.eval(Main.UserApp, :(up())))

  nothing
end

const go = loadapp


"""
    startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websockets_port, async::Bool = ! Genie.config.run_as_server) :: Nothing

Starts the web server. Alias for `AppServer.startup`

# Arguments
- `port::Int`: the port used by the web server
- `host::String`: the host used by the web server
- `ws_port::Int`: the port used by the Web Sockets server
- `async::Bool`: run the web server task asynchronously

# Examples
```julia-repl
julia> startup(8000, "127.0.0.1", async = false)
[ Info: Ready!
Web Server starting at http://127.0.0.1:8000
```
"""
const startup = AppServer.startup
const up = startup
const down = AppServer.down
const isrunning = AppServer.isrunning
const down! = AppServer.down!


### PRIVATE ###

"""
    run() :: Nothing

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
Used internally to parse command line arguments.
"""
function run(; server::Union{Sockets.TCPServer,Nothing} = nothing) :: Nothing
  Commands.execute(Genie.config, server = server)

  nothing
end


"""
    genie() :: Union{Nothing,Sockets.TCPServer}
"""
function genie(; context = @__MODULE__) :: Union{Nothing,Sockets.TCPServer}
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")

  ### EARLY BIND TO PORT FOR HOSTS WITH TIMEOUT ###
  EARLYBINDING = if haskey(ENV, "EARLYBIND") && lowercase(ENV["EARLYBIND"]) == "true" && haskey(ENV, "PORT")
    @info "Binding to host $(ENV["HOST"]) and port $(ENV["PORT"]) \n"
    try
      Sockets.listen(parse(Sockets.IPAddr, ENV["HOST"]), parse(Int, ENV["PORT"]))
    catch ex
      @error ex

      @warn "Failed binding! \n"
      nothing
    end
  else
    nothing
  end

  ### OFF WE GO! ###
  push!(LOAD_PATH, pwd(), "src")

  load(context = context)
  run(server = EARLYBINDING)

  EARLYBINDING
end

const bootstrap = genie

end
