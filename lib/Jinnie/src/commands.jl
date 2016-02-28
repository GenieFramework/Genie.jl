function run_app_with_command_line_args(config) 
  parsed_args = parse_commandline_args()

  if ( parsed_args["db:init"] != nothing ) 
    config.running_as_task = true
    Database.create_database() 
    Database.create_migrations_table()
  elseif ( parsed_args["db:migrations:status"] != nothing )
    Migrations.status()
  elseif ( parsed_args["db:migration:new"] != nothing )
    Migrations.new(parsed_args, config)
  elseif (  parsed_args["db:migration:up"] == "true" )
    Migrations.last_up()
  elseif (  parsed_args["db:migration:up"] != nothing )
    Migrations.up_by_class_name(parsed_args["db:migration:up"])
  elseif (  parsed_args["db:migration:down"] == "true" )
    Migrations.last_down()
  elseif (  parsed_args["db:migration:down"] != nothing )
    Migrations.down_by_class_name(parsed_args["db:migration:down"])
  elseif (  parsed_args["tasks:list"] == "true" )
    list_tasks()
  elseif (  parsed_args["task:run"] != nothing )
    run_task(parsed_args["task:run"])
  else 
    config.auto_connect = true
    jinnie_app.server = startup(parsed_args) 
  end
end