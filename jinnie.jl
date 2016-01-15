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

(function startup()
  parsed_args = parse_commandline_args()
  parsed_args["s"] == "s" ? Jinnie.start_server() : nothing
end)()

end