type Config
  server_port
  app_env
  loggers
  running_as_task
  auto_connect
  supress_output
  db_migrations_table_name
  db_migrations_folder 
  tasks_folder

  Config(;  server_port = 8000, 
            app_env = "dev", 
            loggers = [], 
            running_as_task = false, 
            auto_connect = false, 
            supress_output = false, 
            db_migrations_table_name = "schema_migrations", 
            db_migrations_folder = abspath(joinpath("db", "migrations")), 
            tasks_folder = abspath(joinpath("tasks")) ) = 
              new(server_port, app_env, loggers, running_as_task, auto_connect, supress_output, 
                  db_migrations_table_name, db_migrations_folder, tasks_folder)
end