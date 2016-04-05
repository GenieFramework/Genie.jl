using Logging

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

  Config(;  
            server_port = 8000, 
            app_env = "dev", 
            loggers = [], 
            running_as_task = false, 
            auto_connect = false, 
            supress_output = false, 
            db_migrations_table_name = "schema_migrations", 
            db_migrations_folder = abspath(joinpath("db", "migrations")), 
            task_folder = abspath(joinpath("task")), 
            test_folder = abspath(joinpath("test")), 
            output_length = 100_000_000
        ) = 
              new(server_port, app_env, loggers, running_as_task, auto_connect, supress_output, 
                  db_migrations_table_name, db_migrations_folder, task_folder, test_folder, output_length)
end

const DEV = "dev"
const PROD = "prod"
const TEST = "test"

is_dev() = config.app_env == DEV
is_prod() = config.app_env == PROD
is_test() = config.app_env = TEST