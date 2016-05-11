module Jinnie

using App
using Configuration

export config
export JinnieModel, M, Model, Database

const APP_PATH = pwd()

include(abspath("lib/Jinnie/src/logger.jl"))
include(abspath("lib/Jinnie/src/jinnie_app.jl"))
const jinnie_app = Jinnie_App(App.config)

include(abspath("lib/Jinnie/src/macros.jl"))
include(abspath("lib/Jinnie/src/bootstrap.jl"))
include(abspath("lib/Jinnie/src/commands.jl"))

run_app_with_command_line_args(config)

end