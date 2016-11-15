module Configuration

using Genie

export is_dev, is_prod, is_test, Config, DEV, PROD, TEST, IN_REPL
export RENDER_MUSTACHE_EXT, RENDER_EJL_EXT, RENDER_JSON_EXT, RENDER_EJL_WITH_CACHE
export MODEL_RELATIONSHIPS_EAGERNESS_AUTO, MODEL_RELATIONSHIPS_EAGERNESS_LAZY, MODEL_RELATIONSHIPS_EAGERNESS_EAGER
export LOG_LEVEL_VERBOSITY_VERBOSE, LOG_LEVEL_VERBOSITY_MINIMAL

const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

const RENDER_MUSTACHE_EXT   = "jl.mustache"
const RENDER_JSON_EXT       = "jl.json"
const RENDER_EJL_EXT        = "jl.html"

const MODEL_RELATIONSHIPS_EAGERNESS_AUTO    = :auto
const MODEL_RELATIONSHIPS_EAGERNESS_LAZY    = :lazy
const MODEL_RELATIONSHIPS_EAGERNESS_EAGER   = :eager

const LOG_LEVEL_VERBOSITY_VERBOSE = :verbose
const LOG_LEVEL_VERBOSITY_MINIMAL = :minimal

const IN_REPL = false
const GENIE_VERSION = v"0.6"

is_dev()  = (Genie.config.app_env == DEV)
is_prod() = (Genie.config.app_env == PROD)
is_test() = (Genie.config.app_env == TEST)

type Config
  server_port::Int
  server_workers_count::Int
  server_document_root::String
  server_handle_static_files::Bool
  server_signature::String

  app_env::String
  app_is_api::Bool

  suppress_output::Bool
  output_length::Int

  db_migrations_table_name::String
  db_migrations_folder::String
  db_config_settings::Dict{String,Any}
  db_adapter::Symbol

  tasks_folder::String
  test_folder::String
  session_folder::String
  log_folder::String

  cache_folder::String
  cache_adapter::Symbol
  cache_duration::Int

  log_router::Bool
  log_db::Bool
  log_queries::Bool
  log_requests::Bool
  log_responses::Bool
  log_resources::Bool
  log_level::String
  log_verbosity::Symbol
  log_formatted::Bool
  log_cache::Bool

  assets_path::String
  assets_serve::Bool

  pagination_default_items_per_page::Int
  pagination_page_param_name::String

  model_relationships_eagerness::Symbol

  tests_force_test_env::Bool

  session_auto_start::Bool
  session_key_name::String
  session_storage::Symbol

  inflector_irregulars::Vector{Tuple{String,String}}

  Config(;
            server_port                 = 8000, # default port for binding the web server
            server_workers_count        = 1,
            server_document_root        = "public",
            server_handle_static_files  = true,
            server_signature            = "Genie/$GENIE_VERSION/Julia/$VERSION",

            app_env       = ENV["GENIE_ENV"],
            app_is_api    = true,

            suppress_output = false,
            output_length   = 10_000, # where to truncate strings in console

            db_migrations_table_name  = "schema_migrations",
            db_migrations_folder      = abspath(joinpath("db", "migrations")),
            db_config_settings        = Dict{String,Any}(),
            db_adapter                = :PostgreSQLDatabaseAdapter,

            task_folder       = abspath(joinpath("task")),
            test_folder       = abspath(joinpath("test")),
            session_folder    = abspath(joinpath("session")),
            log_folder        = abspath(joinpath("log")),

            cache_folder      = abspath(joinpath("cache")),
            cache_adapter     = :FileCacheAdapter,
            cache_duration    = 0,

            log_router    = false,
            log_db        = true,
            log_queries   = true,
            log_requests  = true,
            log_responses = true,
            log_resources = false,
            log_level     = "debug",
            log_verbosity = LOG_LEVEL_VERBOSITY_VERBOSE,
            log_formatted = true,
            log_cache     = true,

            assets_path   = "/",
            assets_serve  =  true,

            pagination_default_items_per_page = 20,
            pagination_page_param_name = "page",

            model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY,

            tests_force_test_env = true,

            session_auto_start  = true,
            session_key_name    = "__GENIESID",
            session_storage     = :File,

            inflector_irregulars = Tuple{AbstractString, AbstractString}[]
        ) =
              new(
                  server_port, server_workers_count, server_document_root, server_handle_static_files, server_signature,
                  app_env, app_is_api,
                  suppress_output, output_length,
                  db_migrations_table_name, db_migrations_folder, db_config_settings, db_adapter,
                  task_folder, test_folder, session_folder, log_folder,
                  cache_folder, cache_adapter, cache_duration,
                  log_router, log_db, log_queries, log_requests, log_responses, log_resources, log_level, log_verbosity, log_formatted, log_cache,
                  assets_path, assets_serve,
                  pagination_default_items_per_page, pagination_page_param_name,
                  model_relationships_eagerness,
                  tests_force_test_env,
                  session_auto_start, session_key_name, session_storage,
                  inflector_irregulars)
end

end
