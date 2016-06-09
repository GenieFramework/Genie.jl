module Genie

using App
using Configuration

export Model, Database

const APP_PATH = pwd()

const GENIE_MODEL_FILE_NAME = "model.jl"
const GENIE_CONTROLLER_FILE_NAME = "controller.jl"
const GENIE_VALIDATOR_FILE_NAME = "validation.jl"
const GENIE_AUTHORIZATOR_FILE_NAME = "authorization.jl"

include(abspath("lib/Genie/src/logger.jl"))
include(abspath("lib/Genie/src/genie_app.jl"))
const genie_app = Genie_App(App.config)

include(abspath("lib/Genie/src/macros.jl"))
include(abspath("lib/Genie/src/bootstrap.jl"))
include(abspath("lib/Genie/src/commands.jl"))

run_app_with_command_line_args(Configuration.config)

end