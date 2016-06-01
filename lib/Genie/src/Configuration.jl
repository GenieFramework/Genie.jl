module Configuration

using App
using Logging

export is_dev, is_prod, is_test, Config, DEV, PROD, TEST
export MODEL_RELATIONSHIPS_EAGERNESS_AUTO, MODEL_RELATIONSHIPS_EAGERNESS_LAZY, MODEL_RELATIONSHIPS_EAGERNESS_EAGER

const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

const MODEL_RELATIONSHIPS_EAGERNESS_AUTO    = :auto
const MODEL_RELATIONSHIPS_EAGERNESS_LAZY    = :lazy
const MODEL_RELATIONSHIPS_EAGERNESS_EAGER   = :eager

is_dev()  = App.config.app_env == DEV
is_prod() = App.config.app_env == PROD
is_test() = App.config.app_env == TEST

type Config
  server_port::Int
  app_env::AbstractString

  loggers::Array{Logging.Logger}
  supress_output::Bool
  
  db_migrations_table_name::AbstractString
  db_migrations_folder::AbstractString

  tasks_folder::AbstractString
  test_folder::AbstractString

  output_length::Int 
  
  debug_router::Bool
  debug_db::Bool
  debug_requests::Bool
  debug_responses::Bool

  pagination_jsonapi_default_items_per_page::Int
  pagination_jsonapi_page_param_name::AbstractString

  server_workers_count::Int

  model_relationships_eagerness::Symbol 

  Config(;  
            server_port = 8000, # default port for binding the web server
            app_env = ENV["GENIE_ENV"], 
            
            loggers = [], 
            supress_output = false, 
            
            db_migrations_table_name = "schema_migrations", 
            db_migrations_folder = abspath(joinpath("db", "migrations")), 

            task_folder = abspath(joinpath("task")), 
            test_folder = abspath(joinpath("test")), 

            output_length = 10_000, # where to truncate strings in console

            debug_router = false, 
            debug_db = true, 
            debug_requests = true, 
            debug_responses = true, 

            pagination_jsonapi_default_items_per_page = 20, 
            pagination_jsonapi_page_param_name = "page", 

            server_workers_count = 1, 

            model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY
        ) = 
              new(server_port, app_env, loggers, supress_output, 
                  db_migrations_table_name, db_migrations_folder, task_folder, test_folder, output_length, 
                  debug_router, debug_db, debug_requests, debug_responses, 
                  pagination_jsonapi_default_items_per_page, pagination_jsonapi_page_param_name, 
                  server_workers_count, model_relationships_eagerness)
end

end