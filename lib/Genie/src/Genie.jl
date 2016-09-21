module Genie

include(abspath(joinpath("lib/Genie/src/constants.jl")))

include(abspath(joinpath("config", "env", ENV["GENIE_ENV"] * ".jl")))
include(abspath(joinpath("config", "app.jl")))
include(abspath("lib/Genie/src/macros.jl"))

push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "database_adapters")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "cache_adapters")))
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "session_adapters")))

push!(LOAD_PATH, abspath(joinpath("app", "resources")))
push!(LOAD_PATH, abspath(joinpath("app", "helpers")))

include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

const state = State()
export state

function startup(parsed_args = Dict{AbstractString,Any}(), start_server = false)
  isempty(parsed_args) && (parsed_args = Commands.parse_commandline_args())

  if parsed_args["s"] == "s" || start_server == true
    state.server_workers = AppServer.start(Genie.config.server_port)

    println()
    Logger.log("Started Genie server session", :info)

    while true
      sleep(1_000_000_000)
    end
  end

  false
end

function cache_enabled()
  config.cache_duration > 0
end

using Configuration, Logger, AppServer, Commands, App

include(abspath("lib/Genie/src/commands.jl"))
Commands.execute(Configuration.config)

end