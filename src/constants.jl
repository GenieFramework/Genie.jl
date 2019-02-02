const DOC_ROOT_PATH   = "public"
const CONFIG_PATH     = "config"
const ENV_PATH        = joinpath(CONFIG_PATH, "env")
const APP_PATH        = "app"
const RESOURCES_PATH  = joinpath(APP_PATH, "resources")
const TEST_PATH       = "test"
const TEST_PATH_UNIT  = joinpath(TEST_PATH, "unit")
const LIB_PATH        = "lib"
const HELPERS_PATH    = joinpath(APP_PATH, "helpers")
const LOG_PATH        = "log"
const LAYOUTS_PATH    = joinpath(APP_PATH, "layouts")
const TASKS_PATH      = "tasks"
const BUILD_PATH      = "build"

const GENIE_AUTHORIZATOR_FILE_NAME      = "authorization.yml"
const GENIE_DB_CONFIG_FILE_NAME         = "database.yml"

const GENIE_CONTROLLER_FILE_POSTFIX     = "Controller.jl"
const GENIE_CHANNEL_FILE_POSTFIX        = "Channel.jl"

const ROUTES_FILE_NAME  = joinpath(CONFIG_PATH, "routes.jl")
const CHANNELS_FILE_NAME  = joinpath(CONFIG_PATH, "channels.jl")

const PARAMS_REQUEST_KEY    = :REQUEST
const PARAMS_RESPONSE_KEY   = :RESPONSE
const PARAMS_SESSION_KEY    = :SESSION
const PARAMS_FLASH_KEY      = :FLASH
const PARAMS_ACL_KEY        = :ACL
const PARAMS_WS_CLIENT      = :WS_CLIENT
const PARAMS_JSON_PAYLOAD   = :JSON_PAYLOAD
const PARAMS_TEXT_PAYLOAD   = :TEXT_PAYLOAD
const PARAMS_RAW_PAYLOAD    = :RAW_PAYLOAD

const TEST_FILE_IDENTIFIER = "_test.jl"

# Used to store log info during app bootstrap, when the logger itself is not available.
# The queue is automatically emptied by the logger upon load.
const GENIE_LOG_QUEUE = Vector{Tuple{String,Symbol}}()

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"
