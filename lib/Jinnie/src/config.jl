using Logging

export is_dev, is_prod, is_test

const DEV = "dev"
const PROD = "prod"
const TEST = "test"

is_dev() = Jinnie.config.app_env == DEV
is_prod() = Jinnie.config.app_env == PROD
is_test() = Jinnie.config.app_env = TEST

type Config
  server_port::Int
  app_env::AbstractString
  loggers::Array{Logging.Logger}
  running_as_task::Bool
  auto_connect::Bool
  supress_output::Bool
  db_migrations_table_name::AbstractString
  db_migrations_folder::AbstractString
  tasks_folder::AbstractString
  test_folder::AbstractString
  output_length::Int # where to truncate strings in console
  
  debug_router::Bool
  debug_db::Bool
  debug_requests::Bool
  debug_responses::Bool

  Config(;  
            server_port = 8000, 
            app_env = DEV, 
            loggers = [], 
            running_as_task = false, 
            auto_connect = false, 
            supress_output = false, 
            db_migrations_table_name = "schema_migrations", 
            db_migrations_folder = abspath(joinpath("db", "migrations")), 
            task_folder = abspath(joinpath("task")), 
            test_folder = abspath(joinpath("test")), 
            output_length = 10_000, 

            debug_router = false, 
            debug_db = true, 
            debug_requests = true, 
            debug_responses = true
        ) = 
              new(server_port, app_env, loggers, running_as_task, auto_connect, supress_output, 
                  db_migrations_table_name, db_migrations_folder, task_folder, test_folder, output_length, 
                  debug_router, debug_db, debug_requests, debug_responses)
end