const ROOT_PATH       = pwd()
const DOC_ROOT_PATH   = ROOT_PATH * "/public"
const CONFIG_PATH     = ROOT_PATH * "/config"
const ENV_PATH        = CONFIG_PATH * "/env"
const APP_PATH        = ROOT_PATH * "/app"
const RESOURCE_PATH   = APP_PATH * "/resources"
const TEST_PATH       = ROOT_PATH * "/test"
const TEST_PATH_UNIT  = TEST_PATH * "/unit"
const LIB_PATH        = ROOT_PATH * "/lib"
const HELPERS_PATH    = APP_PATH * "/helpers"
const LOG_PATH        = ROOT_PATH * "/log"

const GENIE_MODEL_FILE_NAME             = "model.jl"
const GENIE_CONTROLLER_FILE_NAME        = "controller.jl"
const GENIE_VALIDATOR_FILE_NAME         = "validator.jl"
const GENIE_AUTHORIZATOR_FILE_NAME      = "authorization.yml"
const GENIE_DB_CONFIG_FILE_NAME         = "database.yml"

const PARAMS_REQUEST_KEY    = :REQUEST
const PARAMS_RESPONSE_KEY   = :RESPONSE
const PARAMS_SESSION_KEY    = :SESSION
const PARAMS_FLASH_KEY      = :FLASH
const PARAMS_ACL_KEY        = :ACL

const TEST_FILE_IDENTIFIER = "_test.jl"