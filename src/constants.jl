const INITIALIZERS_FOLDER = "initializers"

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
const PLUGINS_PATH    = "plugins"
const SESSIONS_PATH   = "sessions"
const CACHE_PATH      = "cache"
const INITIALIZERS_PATH = joinpath(CONFIG_PATH, INITIALIZERS_FOLDER)
const DB_PATH         = "db"
const BIN_PATH        = "bin"
const SRC_PATH        = "src"
const NEW_APP_PATH    = joinpath("files", "new_app")

const GENIE_CONTROLLER_FILE_POSTFIX     = "Controller.jl"

const ROUTES_FILE_NAME  = "routes.jl"
const ASSETS_FINGERPRINT_INITIALIZER_FILE_NAME = "assets_fingerprint.jl"
const SEARCHLIGHT_INITIALIZER_FILE_NAME = "searchlight.jl"
const SECRETS_FILE_NAME = "secrets.jl"
const BOOTSTRAP_FILE_NAME = "bootstrap.jl"
const ENV_FILE_NAME = "env.jl"
const GENIE_FILE_NAME = "genie.jl"
const GLOBAL_ENV_FILE_NAME = "global.jl"
const TESTS_FILE_NAME = "runtests.jl"

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
const PARAMS_ROUTE_KEY      = :ROUTE
const PARAMS_CHANNELS_KEY   = :CHANNEL

const TEST_FILE_IDENTIFIER = "_test.jl"

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"

SECRET_TOKEN = ""
ASSET_FINGERPRINT = ""