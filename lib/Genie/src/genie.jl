module Genie

using App
using Configuration

export config
export AbstractModel, M, Model, Database

const APP_PATH = pwd()

include(abspath("lib/Genie/src/logger.jl"))
include(abspath("lib/Genie/src/genie_app.jl"))
const genie_app = Genie_App(App.config)

include(abspath("lib/Genie/src/macros.jl"))
include(abspath("lib/Genie/src/bootstrap.jl"))
include(abspath("lib/Genie/src/commands.jl"))

run_app_with_command_line_args(config)

end