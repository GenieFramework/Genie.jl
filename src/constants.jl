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
const TASKS_PATH      = "task"
const BUILD_PATH      = "build"
const PLUGINS_PATH    = "plugins"
const SESSIONS_PATH   = "sessions"
const CACHE_PATH      = "cache"

const GENIE_CONTROLLER_FILE_POSTFIX     = "Controller.jl"

const ROUTES_FILE_NAME  = "routes.jl"

const PARAMS_REQUEST_KEY    = :REQUEST
const PARAMS_RESPONSE_KEY   = :RESPONSE
const PARAMS_SESSION_KEY    = :SESSION
const PARAMS_FLASH_KEY      = :FLASH
const PARAMS_POST_KEY       = :POST
const PARAMS_GET_KEY        = :GET
const PARAMS_WS_CLIENT      = :WS_CLIENT
const PARAMS_JSON_PAYLOAD   = :JSON_PAYLOAD
const PARAMS_RAW_PAYLOAD    = :RAW_PAYLOAD
const PARAMS_FILES          = :FILES

const TEST_FILE_IDENTIFIER = "_test.jl"

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"
