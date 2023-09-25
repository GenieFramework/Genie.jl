"""
Handles command line arguments for the genie.jl script.
"""
module Commands

import Sockets
import ArgParse
import Genie
using Logging

"""
    execute(config::Settings) :: Nothing

Runs the requested Genie app command, based on the `args` passed to the script.
"""
function execute(config::Genie.Configuration.Settings; server::Union{Sockets.TCPServer,Nothing} = nothing) :: Nothing
  parsed_args = parse_commandline_args(config)::Dict{String,Any}

  # overwrite env settings with command line arguments
  Genie.config.server_port = parse(Int, parsed_args["p"])
  Genie.config.websockets_port = lowercase(parsed_args["w"]) == "nothing" ? nothing : parse(Int, parsed_args["w"])
  Genie.config.server_host = parsed_args["l"]
  Genie.config.websockets_exposed_host = lowercase(parsed_args["x"]) == "nothing" ? nothing : parsed_args["x"]
  Genie.config.websockets_exposed_port = lowercase(parsed_args["y"]) == "nothing" ? nothing : parse(Int, parsed_args["y"])
  Genie.config.websockets_base_path = parsed_args["W"]
  Genie.config.base_path = parsed_args["b"]

  if (called_command(parsed_args, "s") && lowercase(get(parsed_args, "s", "false")) == "true") ||
      (haskey(ENV, "STARTSERVER") && parse(Bool, ENV["STARTSERVER"])) ||
      (haskey(ENV, "EARLYBIND") && lowercase(get(ENV, "STARTSERVER", "true")) != "false")
    Genie.config.run_as_server = true
    Base.invokelatest(Genie.up, Genie.config.server_port, Genie.config.server_host; server = server)

  elseif called_command(parsed_args, "r")
    endswith(parsed_args["r"], "Task") || (parsed_args["r"] *= "Task")
    Genie.Toolbox.loadtasks()
    taskname = parsed_args["r"] |> Symbol
    task = getfield(Main.UserApp, taskname)

    if parsed_args["a"] !== nothing
      Base.@invokelatest task.runtask(parsed_args["a"])
    else
      Base.@invokelatest task.runtask()
    end
  end

  nothing
end


"""
    parse_commandline_args() :: Dict{String,Any}

Extracts the command line args passed into the app and returns them as a `Dict`, possibly setting up defaults.
Also, it is used by the ArgParse module to populate the command line help for the app `-h`.
"""
function parse_commandline_args(config::Genie.Configuration.Settings) :: Dict{String,Any}
  settings = ArgParse.ArgParseSettings()

  settings.description = "Genie web framework CLI"
  settings.epilog = "Visit https://genieframework.com for more info"

  ArgParse.@add_arg_table! settings begin
    "-s"
    help = "Starts HTTP server"

    "-p"
    help = "Web server port"
    default = "$(config.server_port)"

    "-w"
    help = "WebSockets server port"
    default = "$(config.websockets_port)"

    "-l"
    help = "Host IP to listen on"
    default = "$(config.server_host)"

    "-x"
    help = "WebSockets host used by the clients"
    default = "$(config.websockets_exposed_host)"

    "-y"
    help = "WebSockets port used by the clients"
    default = "$(config.websockets_exposed_port)"

    "-W"
    help = "Websockets base path, e.g. `websocket`, `stream`"
    default = "$(config.websockets_base_path)"

    "-b"
    help = "Base path for serving assets and building links"
    default = "$(config.base_path)"

    "-r"
    help = "runs Genie.Toolbox task"

    "-a"
    help = "additional arguments passed into the Genie.Toolbox `runtask` function"
    default = nothing
  end

  ArgParse.parse_args(settings)
end


"""
    called_command(args::Dict, key::String) :: Bool

Checks whether or not a certain command was invoked by looking at the command line args.
"""
function called_command(args::Dict{String,Any}, key::String) :: Bool
  haskey(args, key) && args[key] !== nothing
end

end
