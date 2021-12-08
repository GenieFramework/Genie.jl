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
  Genie.config.app_env = ENV["GENIE_ENV"]
  Genie.config.server_port = haskey(ENV, "PORT") ? parse(Int, ENV["PORT"]) : parse(Int, parsed_args["p"])
  Genie.config.websockets_port = haskey(ENV, "WSPORT") ? parse(Int, ENV["WSPORT"]) : parse(Int, parsed_args["w"])
  Genie.config.server_host = parsed_args["l"]

  if called_command(parsed_args, "s") || (haskey(ENV["STARTSERVER"]) && parse(Bool, ENV["STARTSERVER"]))
    Genie.config.run_as_server = true
    Base.invokelatest(Genie.up, Genie.config.server_port, Genie.config.server_host; server = server)

  elseif called_command(parsed_args, "r")
    endswith(parsed_args["r"], "Task") || (parsed_args["r"] *= "Task")
    Base.invokelatest(Genie.Toolbox.loadtasks, Main.UserApp)
    taskname = parsed_args["r"]
    task = getfield(Main.UserApp, Symbol(taskname))

    if parsed_args["a"] !== nothing
      Base.invokelatest(task.runtask, parsed_args["a"])
    else
      Base.invokelatest(task.runtask)
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
    "s"
    help = "starts HTTP server"

    "-p"
    help = "HTTP server port"
    default = "$(config.server_port)"

    "-w"
    help = "Web Sockets server port"
    default = "$(config.server_port)"

    "-l"
    help = "Host IP to listen on"
    default = "$(config.server_host)"

    "si"
    help = "starts HTTP server and enters REPL"

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
  haskey(args, key) && (args[key] == "true" || args["s"] == key || args[key] !== nothing)
end

end
