"""
Loads dependencies and bootstraps a Genie app. Exposes core Genie functionality.
"""
module Genie

import Inflector

include("Configuration.jl")
using .Configuration

const config = Configuration.Settings()


include("constants.jl")

import Sockets
import Logging

using Reexport

include("HTTPUtils.jl")
include("Exceptions.jl")
include("Repl.jl")
include("Watch.jl")
include("Loader.jl")
include("Secrets.jl")
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
include("Server.jl")
include("Commands.jl")
include("Responses.jl")
include("Requests.jl")
include("Logger.jl")

# === #

export up, down
@reexport using .Router

const assets_config = Genie.Assets.assets_config


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
function loadapp(path::String = "."; autostart::Bool = false, dbadapter::Union{Nothing,Symbol,String} = nothing) :: Nothing
  if ! isnothing(dbadapter) && dbadapter != "nothing"
    Genie.Generator.autoconfdb(dbadapter)
  end

  Core.eval(Main, quote
      include(joinpath($path, $(Genie.BOOTSTRAP_FILE_NAME)))
  end)

  Genie.config.watch && Genie.Watch.watch(path)
  autostart && (Core.eval(Main, :(up())))

  nothing
end

const go = loadapp


"""
    up(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websockets_port, async::Bool = ! Genie.config.run_as_server) :: Nothing

Starts the web server. Alias for `Server.up`

# Arguments
- `port::Int`: the port used by the web server
- `host::String`: the host used by the web server
- `ws_port::Int`: the port used by the Web Sockets server
- `async::Bool`: run the web server task asynchronously

# Examples
```julia-repl
julia> up(8000, "127.0.0.1", async = false)
[ Info: Ready!
Web Server starting at http://127.0.0.1:8000
```
"""
const up = Server.up
const down = Server.down
const isrunning = Server.isrunning
const down! = Server.down!


### PRIVATE ###

"""
    run() :: Nothing

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
Used internally to parse command line arguments.
"""
function run(; server::Union{Sockets.TCPServer,Nothing} = nothing) :: Nothing
  Genie.config.app_env == "test" || Commands.execute(Genie.config, server = server)

  nothing
end


"""
    genie() :: Union{Nothing,Sockets.TCPServer}
"""
function genie(; context = @__MODULE__) :: Union{Nothing,Sockets.TCPServer}
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")

  ### EARLY BIND TO PORT FOR HOSTS WITH TIMEOUT ###
  EARLYBINDING = if haskey(ENV, "EARLYBIND") && lowercase(ENV["EARLYBIND"]) == "true" && haskey(ENV, "PORT")
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

  Secrets.load(context = context)
  Loader.load(context = context)
  Genie.config.watch && @async Watch.watch(pwd())
  run(server = EARLYBINDING)

  EARLYBINDING
end

const bootstrap = genie

end
