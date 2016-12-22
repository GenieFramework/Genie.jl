module Genie

include(abspath(joinpath("lib", "Genie", "src", "constants.jl")))

include(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
include(abspath(joinpath(CONFIG_PATH, "app.jl")))
include(abspath(joinpath(CONFIG_PATH, "plugins.jl")))

push!(LOAD_PATH,  abspath(joinpath(LIB_PATH, "Genie", "src", "cache_adapters")),
                  abspath(joinpath(LIB_PATH, "Genie", "src", "session_adapters")),
                  abspath(joinpath(LIB_PATH, "SearchLight", "src", "database_adapters")),
                  RESOURCE_PATH, HELPERS_PATH)

include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

using Macros, Configuration, Logger, AppServer, Commands, App, Millboard, SearchLight, Renderer

"""
    run() :: Void

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
Automatically invoked.
"""
function run() :: Void
  Configuration.load_db_connection()
  Commands.execute(Configuration.config)
end

run()

end
