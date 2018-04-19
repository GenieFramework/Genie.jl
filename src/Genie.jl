"""
Loads dependencies and bootstraps a Genie app.
"""
module Genie

push!(LOAD_PATH, joinpath(Pkg.dir("Genie"), "src"))

include(joinpath(Pkg.dir("Genie"), "src", "configuration.jl"))

include(joinpath(Pkg.dir("Genie"), "src", "constants.jl"))
if haskey(ENV, "GENIE_ENV") && isfile(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
  isdefined(:config) || include(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
  isfile(abspath(joinpath(CONFIG_PATH, "app.jl"))) && include(abspath(joinpath(CONFIG_PATH, "app.jl")))

  const IS_IN_APP = true
else
  const IS_IN_APP = false
  const config = Configuration.Settings(app_env = Configuration.DEV)
end

const SEARCHLIGHT_ON = isdir(Pkg.dir("SearchLight")) && IS_IN_APP ? true : false

export IS_IN_APP, SEARCHLIGHT_ON


isfile(abspath(joinpath(CONFIG_PATH, "plugins.jl"))) && include(abspath(joinpath(CONFIG_PATH, "plugins.jl")))

push!(LOAD_PATH,  joinpath(Pkg.dir("Genie"), "src", "cache_adapters"),
                  joinpath(Pkg.dir("Genie"), "src", "session_adapters"),
                  RESOURCES_PATH, HELPERS_PATH)

include(joinpath(Pkg.dir("Genie"), "src", "genie_types.jl"))
include(joinpath(Pkg.dir("Genie"), "src", "file_templates.jl"))
include(joinpath(Pkg.dir("Genie"), "src", "generator.jl"))
include(joinpath(Pkg.dir("Genie"), "src", "REPL.jl"))

using Macros, Logger, App, Commands, AppServer, Millboard, Renderer

SEARCHLIGHT_ON && eval(:(using SearchLight))

if IS_IN_APP
  @eval parse("@dependencies")
  include(joinpath(Pkg.dir("Genie"), "src", "deprecations.jl"))
end

"""
    run() :: Void

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
"""
function run() :: Void
  Commands.execute(Genie.config)

  nothing
end

end
