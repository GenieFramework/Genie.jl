function run_app_with_command_line_args(config) 
  parsed_args = parse_commandline_args()

  if ( parsed_args["db:init"] != nothing ) 
    config.running_as_task = true
    Database.create_database() 
    Database.create_migrations_table()
  elseif ( parsed_args["db:migrations:status"] != nothing )
    Migrations.status(parsed_args, config)
  elseif ( parsed_args["db:migration:new"] != nothing )
    Migrations.new(parsed_args, config)
  elseif (  parsed_args["db:migration:up"] != nothing )
    Migrations.last_up(parsed_args, config)
  elseif (  parsed_args["db:migration:down"] != nothing )
    Migrations.last_down(parsed_args, config)
  else 
    config.auto_connect = true
    jinnie_app.server = startup(parsed_args) 
  end
end