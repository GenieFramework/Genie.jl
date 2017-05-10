"""
Loads dependencies and bootstraps a Genie app.
"""
module Genie

push!(LOAD_PATH, joinpath(Pkg.dir("Genie"), "src"))

using Configuration

include(joinpath(Pkg.dir("Genie"), "src", "constants.jl"))
if haskey(ENV, "GENIE_ENV") && isfile(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
  include(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
  isfile(abspath(joinpath(CONFIG_PATH, "app.jl"))) && include(abspath(joinpath(CONFIG_PATH, "app.jl")))

  const IS_IN_APP = true
else
  const IS_IN_APP = false
end
export IS_IN_APP

isfile(abspath(joinpath(CONFIG_PATH, "plugins.jl"))) && include(abspath(joinpath(CONFIG_PATH, "plugins.jl")))

push!(LOAD_PATH,  joinpath(Pkg.dir("Genie"), "src", "cache_adapters"),
                  joinpath(Pkg.dir("Genie"), "src", "session_adapters"),
                  RESOURCE_PATH, HELPERS_PATH)

include(joinpath(Pkg.dir("Genie"), "src", "genie_types.jl"))
include(joinpath(Pkg.dir("Genie"), "src", "REPL.jl"))

using Macros, Logger, AppServer, Commands, App, Millboard, SearchLight, Renderer

IS_IN_APP && @eval parse("@dependencies")

"""
    run() :: Void

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
"""
function run() :: Void
  Configuration.load_db_connection()
  Commands.execute(Configuration.config)
end

end
