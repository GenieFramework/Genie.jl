"""
Handles command line arguments for the genie.jl script.
"""
module Commands

import Sockets
import ArgParse
import Genie, Genie.Configuration, Genie.AppServer

"""
    execute(config::Settings) :: Nothing

Runs the requested Genie app command, based on the `args` passed to the script.
"""
function execute(config::Genie.Configuration.Settings; server::Union{Sockets.TCPServer,Nothing} = nothing) :: Nothing
  parsed_args = parse_commandline_args(config)::Dict{String,Any}

  # overwrite env settings with command line arguments
  Genie.config.app_env = ENV["GENIE_ENV"]
  Genie.config.server_port = haskey(ENV, "PORT") ? parse(Int, ENV["PORT"]) : parse(Int, parsed_args["server:port"])
  Genie.config.server_host = parsed_args["server:host"]

  if called_command(parsed_args, "s") || called_command(parsed_args, "server:start")
    Genie.config.run_as_server = true
    AppServer.startup(Genie.config.server_port, Genie.config.server_host, server = server)
  elseif called_command(parsed_args, "si") || called_command(parsed_args, "server:interactive")
    AppServer.startup(Genie.config.server_port, Genie.config.server_host, server = server)
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
  settings.version = string(Genie.Configuration.GENIE_VERSION)
  settings.add_version = true

  ArgParse.@add_arg_table settings begin
    "s"
    help = "starts HTTP server"
    "--server:start"
    help = "starts HTTP server"
    "--server:port", "-p"
    help = "HTTP server port"
    default = "$(config.server_port)"
    "--server:host", "-l"
    help = "Host IP to listen on"
    default = "$(config.server_host)"
    "si"
    help = "starts HTTP server and enters REPL"
    "--server:interactive"
    help = "starts HTTP server and enters REPL"
  end

  ArgParse.parse_args(settings)
end


"""
    called_command(args::Dict, key::String) :: Bool

Checks whether or not a certain command was invoked by looking at the command line args.
"""
function called_command(args::Dict{String,Any}, key::String) :: Bool
  args[key] == "true" || args["s"] == key
end

end
