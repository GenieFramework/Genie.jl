"""
Loads dependencies and bootstraps a Genie app.
"""
module Genie

push!(LOAD_PATH, @__DIR__)

include(joinpath(@__DIR__, "Configuration.jl"))
include(joinpath(@__DIR__, "constants.jl"))

config = Configuration.Settings(app_env = Configuration.DEV)

using Revise

isfile(joinpath(CONFIG_PATH, "plugins.jl")) && include(joinpath(CONFIG_PATH, "plugins.jl"))

push!(LOAD_PATH,  joinpath(@__DIR__, "cache_adapters"),
                  joinpath(@__DIR__, "session_adapters"),
                  RESOURCES_PATH, HELPERS_PATH)

include(joinpath(@__DIR__, "genie_types.jl"))

include("Loggers.jl")
include("Inflector.jl")
include("Util.jl")
include("FileTemplates.jl")
include("Generator.jl")
include("Tester.jl")
include("Encryption.jl")
include("Cookies.jl")
include("Sessions.jl")
include("Input.jl")
include("Flax.jl")
include("Renderer.jl")
include("Assets.jl")
include("Router.jl")
include("Helpers.jl")
include("WebChannels.jl")
include("AppServer.jl")
include("Commands.jl")
include("Cache.jl")
include("Responses.jl")
include("Requests.jl")

using .Loggers
using .Inflector, .Util
using .FileTemplates, .Generator, .Tester, .Encryption, .Cookies, .Sessions
using .Input, .Renderer, .Assets, .Router, .Helpers, .AppServer, .Commands
using .Flax, .AppServer

include(joinpath(@__DIR__, "REPL.jl"))

"""
    run() :: Nothing

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
"""
function run() :: Nothing
  Commands.execute(Genie.config)

  nothing
end


"""
    newapp(path = "."; autostart = true, fullstack = true, dbsupport = true) :: Nothing

Scaffolds a new Genie app.
"""
function newapp(path = "."; autostart = true, fullstack = true, dbsupport = true) :: Nothing
  REPL.newapp(path, autostart = autostart, fullstack = fullstack, dbsupport = dbsupport)
end
const new_app = newapp


"""
"""
function loadapp(path = "."; autostart = false) :: Nothing
  REPL.loadapp(path, autostart = autostart)
end


"""
    startup()

Starts the web server.
```
"""
function startup(port::Int = 8000, host::String = Genie.config.server_host;
                  wsport::Int = port + 1, async::Bool = ! Genie.config.run_as_server,
                  verbose::Bool = false, ratelimit::Union{Rational{Int},Nothing} = nothing)

  AppServer.startup(port, host, ws_port = wsport, async = async, verbose = verbose, ratelimit = ratelimit)
end

end
