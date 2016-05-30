using ArgParse

function called_command(args, key)
    args[key] == "true" || args["s"] == key
end

function run_app_with_command_line_args(config) 
  parsed_args = parse_commandline_args()::Dict{AbstractString, Any}

  config.app_env = ENV["GENIE_ENV"]
  config.server_port = parse(Int, parsed_args["server:port"])
  config.server_workers_count = parse(Int, parsed_args["server:workers"])

  if ( called_command(parsed_args, "db:init") ) 
    Database.create_database()
    Database.create_migrations_table()

  elseif ( called_command(parsed_args, "migration:status") )
    Migration.status()
  elseif ( parsed_args["migration:new"] != nothing )
    Genie.load_file_templates()
    Migration.new(parsed_args, config)

  elseif (  called_command(parsed_args, "migration:up") )
    Migration.last_up()
  elseif (  parsed_args["migration:up"] != nothing )
    Migration.up_by_class_name(parsed_args["migration:up"])

  elseif (  called_command(parsed_args, "migration:down") )
    Migration.last_down()
  elseif (  parsed_args["migration:down"] != nothing )
    Migration.down_by_class_name(parsed_args["db:migration:down"])
  
  elseif (  called_command(parsed_args, "task:list") )
    Toolbox.print_all_tasks()
  elseif (  parsed_args["task:run"] != nothing )
    Toolbox.run_task(parsed_args["task:run"])
  elseif ( parsed_args["task:new"] != nothing )
    ! endswith(parsed_args["task:new"], "_task") && (parsed_args["task:new"] *= "_task")
    Genie.load_file_templates()
    Toolbox.new(parsed_args, config)

  elseif (  called_command(parsed_args, "test:run") )
    config.app_env = "test"
    Tester.run_all_tests(parsed_args["test:run"], config)

  else 
    Genie.genie_app.server = Genie.startup(parsed_args) 
  end
end

function parse_commandline_args()
    s = ArgParseSettings()

    @add_arg_table s begin
        # "--opt2", "-o"
        #     help = "another option with an argument"
        #     arg_type = Int
        #     default = 0
        # "--flag1"
        #     help = "an option without argument, i.e. a flag"
        #     action = :store_true
        # "arg1"
        #     help = "a positional argument"
        #     required = true
        "s"
            help = "starts HTTP server"
        "--server:port", "-p"
            help = "HTTP server port"
            default = "8000"
        "--server:workers", "-w"
            help = "Number of workers, one per server instance. Additional workers are spawned onto 1 increments of port"
            default = "1"
        
        "--db:init"
            help = "true -> create database and core tables"
            default = "false"
        
        "--migration:status"
            help = "true -> list migrations and their status"
            default = "false"
        "--migration:new"
            help = "migration_name -> create a new migration, ex: create_table_foos"
        "--migration:up"
            help = "true -> run last migration up \n 
                    migration_class_name -> run migration up, ex: CreateTableFoos" 
        "--migration:down"
            help = "true -> run last migration down \n 
                    migration_class_name -> run migration down, ex: CreateTableFoos" 
        
        "--task:list"
            help = "true -> list tasks" 
            default = "false"
        "--task:new"
            help = "task_name -> create a new task, ex: sync_files_task"
        "--task:run"
            help = "task_name -> run task" 

        "--test:run"
            help = "true -> run tests" 
            default = "false"
    end

    return parse_args(s)
end