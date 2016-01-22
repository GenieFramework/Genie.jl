module Jinnie

const APP_PATH = pwd()
loggers = []

push!(LOAD_PATH, abspath("./"))
push!(LOAD_PATH, abspath("config"))
push!(LOAD_PATH, abspath("lib/"))
push!(LOAD_PATH, abspath("lib/Jinnie/src"))
push!(LOAD_PATH, abspath("app/controllers"))

include(abspath("config/loggers.jl"))
include(abspath("config/renderers.jl"))
include(abspath("config/routes.jl"))

include(abspath("lib/Jinnie/src/command_args_parser.jl"))
include(abspath("lib/Jinnie/src/logger.jl"))
include(abspath("lib/Jinnie/src/middlewares.jl"))
include(abspath("lib/Jinnie/src/renderer.jl"))
include(abspath("lib/Jinnie/src/jinnie.jl"))

# manually loaded packages
include(abspath("lib/AnsiColor/src/AnsiColor.jl"))
include(abspath("lib/Mux/src/Mux.jl"))
# include(abspath("lib/Mustache/src/Mustache.jl"))

using AnsiColor

(function startup()
  parsed_args = parse_commandline_args()
  server_port = parsed_args["server-port"] != nothing ? parsed_args["server-port"] : 8000
  parsed_args["s"] == "s" ? Jinnie.start_server(server_port) : println(AnsiColor.cyan("Use the <s> option to start the server"))
end)()

end