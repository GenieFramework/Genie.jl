push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "database_adapters")))
include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

const state = State()
export state

function startup(parsed_args = Dict{AbstractString,Any}(), start_server = false)
  isempty(parsed_args) && (parsed_args = Commands.parse_commandline_args())

  if parsed_args["s"] == "s" || start_server == true
    state.server_workers = AppServer.spawn!(server_workers, Genie.config.server_port)

    println()
    Logger.log("Started Genie server session", :info)

    while true
      sleep(1_000_000_000)
    end
  end

  false
end