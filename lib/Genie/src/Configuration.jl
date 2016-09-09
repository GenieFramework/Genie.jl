module Configuration

using App
using Logging

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

is_dev()  = (App.config.app_env == DEV)
is_prod() = (App.config.app_env == PROD)
is_test() = (App.config.app_env == TEST)

type Config
  server_port::Int
  server_workers_count::Int
  server_document_root::AbstractString
  server_handle_static_files::Bool
  server_signature::ASCIIString

  app_env::AbstractString
  app_is_api::Bool

  suppress_output::Bool
  output_length::Int

  db_migrations_table_name::AbstractString
  db_migrations_folder::AbstractString
  db_auto_connect::Bool

  tasks_folder::AbstractString
  test_folder::AbstractString
  session_folder::AbstractString
  log_folder::AbstractString

  cache_folder::AbstractString
  cache_adapter::Symbol
  cache_duration::Int

  loggers::Array{Logging.Logger,1}
  log_router::Bool
  log_db::Bool
  log_requests::Bool
  log_responses::Bool
  log_resources::Bool
  log_level::Logging.LogLevel
  log_verbosity::Symbol
  log_formatted::Bool
  log_cache::Bool

  assets_path::AbstractString
  assets_serve::Bool

  pagination_default_items_per_page::Int
  pagination_page_param_name::AbstractString

  model_relationships_eagerness::Symbol

  tests_force_test_env::Bool

  session_auto_start::Bool
  session_key_name::AbstractString
  session_storage::Symbol

  inflector_irregulars::Array{Tuple{AbstractString, AbstractString},1}

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
            db_auto_connect           = true,

            task_folder       = abspath(joinpath("task")),
            test_folder       = abspath(joinpath("test")),
            session_folder    = abspath(joinpath("session")),
            log_folder        = abspath(joinpath("log")),

            cache_folder      = abspath(joinpath("cache")),
            cache_adapter     = :FileCacheAdapter,
            cache_duration    = 31536000,

            loggers       = [],
            log_router    = false,
            log_db        = true,
            log_requests  = true,
            log_responses = true,
            log_resources = false,
            log_level     = Logging.DEBUG,
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

            inflector_irregulars = Array{Tuple{AbstractString, AbstractString},1}()
        ) =
              new(
                  server_port, server_workers_count, server_document_root, server_handle_static_files, server_signature,
                  app_env, app_is_api,
                  suppress_output, output_length,
                  db_migrations_table_name, db_migrations_folder, db_auto_connect,
                  task_folder, test_folder, session_folder, log_folder,
                  cache_folder, cache_adapter, cache_duration,
                  loggers, log_router, log_db, log_requests, log_responses, log_resources, log_level, log_verbosity, log_formatted, log_cache,
                  assets_path, assets_serve,
                  pagination_default_items_per_page, pagination_page_param_name,
                  model_relationships_eagerness,
                  tests_force_test_env,
                  session_auto_start, session_key_name, session_storage,
                  inflector_irregulars)
end

end