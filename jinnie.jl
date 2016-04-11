#!/usr/local/bin/julia --color=yes

#__precompile__()
module Jinnie

const APP_PATH = pwd()

include(abspath("lib/Jinnie/src/config.jl"))
const config = Config(output_length = 600)

include(abspath("lib/Jinnie/src/logger.jl"))
include(abspath("lib/Jinnie/src/jinnie_app.jl"))
const jinnie_app = Jinnie_App(config)

include(abspath("lib/Jinnie/src/macros.jl"))
include(abspath("lib/Jinnie/src/bootstrap.jl"))
include(abspath("lib/Jinnie/src/commands.jl"))

run_app_with_command_line_args(config)

end

include(abspath("lib/Jinnie/src/interactive_session.jl")) # interactive session