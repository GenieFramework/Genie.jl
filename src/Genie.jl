module Genie

include(joinpath(Pkg.dir("Genie"), "src", "constants.jl"))

haskey(ENV, "GENIE_ENV") && isfile(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl"))) && include(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
isfile(abspath(joinpath(CONFIG_PATH, "app.jl"))) && include(abspath(joinpath(CONFIG_PATH, "app.jl")))
isfile(abspath(joinpath(CONFIG_PATH, "plugins.jl"))) && include(abspath(joinpath(CONFIG_PATH, "plugins.jl")))

push!(LOAD_PATH,  joinpath(Pkg.dir("Genie"), "src"),
                  joinpath(Pkg.dir("Genie"), "src", "cache_adapters"),
                  joinpath(Pkg.dir("Genie"), "src", "session_adapters"),
                  joinpath(Pkg.dir("SearchLight"), "src"),
                  joinpath(Pkg.dir("SearchLight"), "src", "database_adapters"),
                  RESOURCE_PATH, HELPERS_PATH)

include(joinpath(Pkg.dir("Genie"), "src", "genie_types.jl"))
include(joinpath(Pkg.dir("Genie"), "src", "REPL.jl"))

using Macros, Configuration, Logger, AppServer, Commands, App, Millboard, SearchLight, Renderer

isdefined(Genie, :config) && eval(parse("@dependencies"))

"""
    run() :: Void

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
Automatically invoked.
"""
function run() :: Void
  Configuration.load_db_connection()
  Commands.execute(Configuration.config)
end

end
