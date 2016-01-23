#__precompile__()
module Jinnie

const APP_PATH = pwd()

server_port = 8000
loggers = []

push!(LOAD_PATH, abspath("./"))
push!(LOAD_PATH, abspath("config"))
push!(LOAD_PATH, abspath("lib/"))
push!(LOAD_PATH, abspath("lib/Jinnie/src"))
push!(LOAD_PATH, abspath("app/controllers"))

function load_dependencies()
  # manually loaded packages
  # include(abspath("lib/Mux/src/Mux.jl"))

  include(abspath("config/loggers.jl"))
  include(abspath("config/renderers.jl"))
  include(abspath("config/routes.jl"))

  include(abspath("lib/Jinnie/src/fs_watcher.jl"))

  include(abspath("lib/Jinnie/src/command_args_parser.jl"))
  include(abspath("lib/Jinnie/src/logger.jl"))
  include(abspath("lib/Jinnie/src/middlewares.jl"))
  include(abspath("lib/Jinnie/src/renderer.jl"))
  include(abspath("lib/Jinnie/src/jinnie.jl"))
end

function startup(start_server = false)
  parsed_args = parse_commandline_args()
  server_port = parsed_args["server-port"] != nothing ? parse(Int, parsed_args["server-port"]) : Jinnie.server_port
  if parsed_args["s"] == "s" || start_server == true 
    if parsed_args["monitor"] == "true" 
      Jinnie.start_server(server_port)
      monitor_changes() 
    else
      @sync Jinnie.start_server(server_port) 
    end
  else
    println("Use the <s> option to start the server")
  end
end

load_dependencies()
startup()

end