module Configuration

using App
using Logging

export is_dev, is_prod, is_test, Config, DEV, PROD, TEST, IN_REPL
export MODEL_RELATIONSHIPS_EAGERNESS_AUTO, MODEL_RELATIONSHIPS_EAGERNESS_LAZY, MODEL_RELATIONSHIPS_EAGERNESS_EAGER
export LOG_LEVEL_VERBOSITY_VERBOSE, LOG_LEVEL_VERBOSITY_MINIMAL

const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

const MODEL_RELATIONSHIPS_EAGERNESS_AUTO    = :auto
const MODEL_RELATIONSHIPS_EAGERNESS_LAZY    = :lazy
const MODEL_RELATIONSHIPS_EAGERNESS_EAGER   = :eager

const LOG_LEVEL_VERBOSITY_VERBOSE = :verbose 
const LOG_LEVEL_VERBOSITY_MINIMAL = :minimal

const IN_REPL = false

is_dev()  = (App.config.app_env == DEV)
is_prod() = (App.config.app_env == PROD)
is_test() = (App.config.app_env == TEST)

type Config
  server_port::Int
  app_env::AbstractString

  loggers::Array{Logging.Logger,1}
  supress_output::Bool
  
  db_migrations_table_name::AbstractString
  db_migrations_folder::AbstractString
  db_auto_connect::Bool

  tasks_folder::AbstractString
  test_folder::AbstractString

  output_length::Int 
  
  log_router::Bool
  log_db::Bool
  log_requests::Bool
  log_responses::Bool
  log_resources::Bool

  assets_path::AbstractString
  assets_serve::Bool

  pagination_jsonapi_default_items_per_page::Int
  pagination_jsonapi_page_param_name::AbstractString

  server_workers_count::Int
  server_document_root::AbstractString
  server_handle_static_files::Bool 

  model_relationships_eagerness::Symbol 

  tests_force_test_env::Bool

  log_level::Logging.LogLevel
  log_verbosity::Symbol
  log_formatted::Bool

  inflector_irregulars::Array{Tuple{AbstractString, AbstractString},1}

  Config(;  
            server_port = 8000, # default port for binding the web server
            app_env = ENV["GENIE_ENV"], 
            
            loggers = [], 
            supress_output = false, 
            
            db_migrations_table_name  = "schema_migrations", 
            db_migrations_folder      = abspath(joinpath("db", "migrations")), 
            db_auto_connect           = true, 

            task_folder = abspath(joinpath("task")), 
            test_folder = abspath(joinpath("test")), 

            output_length = 10_000, # where to truncate strings in console

            log_router    = false, 
            log_db        = true, 
            log_requests  = true, 
            log_responses = true, 
            log_resources = false, 

            assets_path   = "/", 
            assets_serve  =  true, 

            pagination_jsonapi_default_items_per_page = 20, 
            pagination_jsonapi_page_param_name = "page", 

            server_workers_count        = 1, 
            server_document_root        = "public",
            server_handle_static_files  = true, 

            model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY,

            tests_force_test_env = true, 

            log_level     = Logging.DEBUG, 
            log_verbosity = LOG_LEVEL_VERBOSITY_VERBOSE, 
            log_formatted = true,

            inflector_irregulars = Array{Tuple{AbstractString, AbstractString},1}()
        ) = 
              new(server_port, app_env, loggers, supress_output, 
                  db_migrations_table_name, db_migrations_folder, db_auto_connect, 
                  task_folder, test_folder, output_length, 
                  log_router, log_db, log_requests, log_responses, log_resources, 
                  assets_path, assets_serve, 
                  pagination_jsonapi_default_items_per_page, pagination_jsonapi_page_param_name, 
                  server_workers_count, server_document_root, server_handle_static_files, 
                  model_relationships_eagerness, tests_force_test_env, 
                  log_level, log_verbosity, log_formatted)
end

end