const NEW_APP_PATH = joinpath("files", "new_app")

const GENIE_CONTROLLER_FILE_POSTFIX             = "Controller.jl"

const ROUTES_FILE_NAME                          = "routes.jl"
const ASSETS_FINGERPRINT_INITIALIZER_FILE_NAME  = "assets_fingerprint.jl"
const SEARCHLIGHT_INITIALIZER_FILE_NAME         = "searchlight.jl"
const SECRETS_FILE_NAME                         = "secrets.jl"
const BOOTSTRAP_FILE_NAME                       = "bootstrap.jl"
const ENV_FILE_NAME                             = "env.jl"
const GENIE_FILE_NAME                           = "genie.jl"
const GLOBAL_ENV_FILE_NAME                      = "global.jl"
const TESTS_FILE_NAME                           = "runtests.jl"

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
const PARAMS_MIME_KEY       = :MIME

SECRET_TOKEN = ""
ASSET_FINGERPRINT = ""