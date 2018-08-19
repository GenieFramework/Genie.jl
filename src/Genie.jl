"""
Loads dependencies and bootstraps a Genie app.
"""
module Genie

push!(LOAD_PATH, @__DIR__)

include(joinpath(@__DIR__, "Configuration.jl"))
include(joinpath(@__DIR__, "constants.jl"))

const config = Configuration.Settings(app_env = Configuration.DEV)

using Revise

isfile(joinpath(CONFIG_PATH, "plugins.jl")) && include(joinpath(CONFIG_PATH, "plugins.jl"))

push!(LOAD_PATH,  joinpath(@__DIR__, "cache_adapters"),
                  joinpath(@__DIR__, "session_adapters"),
                  RESOURCES_PATH, HELPERS_PATH)

include(joinpath(@__DIR__, "genie_types.jl"))

include("Macros.jl")
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
include("Router.jl")
include("Helpers.jl")
include("WebChannels.jl")
include("AppServer.jl")
include("Commands.jl")
include("Cache.jl")

using .Macros, .Loggers
using .Inflector, .Util
using .FileTemplates, .Generator, .Tester, .Encryption, .Cookies, .Sessions, .Input, .Renderer, .Router, .Helpers, .AppServer, .Commands
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
    new_app(path = "."; db_support = false, skip_dependencies = false, autostart = true) :: Nothing

Scaffolds a new Genie app.
"""
function new_app(path = "."; db_support = false, skip_dependencies = false, autostart = false) :: Nothing
  REPL.new_app(path, db_support = db_support, skip_dependencies = skip_dependencies, autostart = autostart)
end

end
