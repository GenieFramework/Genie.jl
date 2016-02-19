#!/usr/local/bin/julia

#__precompile__()
module Jinnie

const APP_PATH = pwd()

include(abspath("lib/Jinnie/src/config.jl"))
const config = Config()

include(abspath("lib/Jinnie/src/logger.jl"))
include(abspath("lib/Jinnie/src/jinnie_app.jl"))
const jinnie_app = Jinnie_App(config)

include(abspath("lib/Jinnie/src/bootstrap.jl"))
include(abspath("lib/Jinnie/src/commands.jl"))

run_app_with_command_line_args(config)

end