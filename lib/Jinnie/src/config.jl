type Config
  server_port
  app_env
  loggers
  running_as_task
  auto_connect
  supress_output
  db_migrations_table_name
  db_migrations_folder 

  Config() = new(8000, "dev", [], false, false, false, "schema_migrations", abspath(joinpath("db", "migrations")))
end