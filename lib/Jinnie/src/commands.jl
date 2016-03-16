@debug function run_app_with_command_line_args(config) 
  parsed_args = parse_commandline_args()

  config.app_env = parsed_args["env"]

  if ( parsed_args["db:init"] == "true" ) 
    Database.create_database()
    Database.create_migrations_table()

  elseif ( parsed_args["db:migrations:status"] == "true" )
    Migration.status()
  elseif ( parsed_args["db:migration:new"] != nothing )
    Migration.new(parsed_args, config)

  elseif (  parsed_args["db:migration:up"] == "true" )
    Migration.last_up()
  elseif (  parsed_args["db:migration:up"] != nothing )
    Migration.up_by_class_name(parsed_args["db:migration:up"])

  elseif (  parsed_args["db:migration:down"] == "true" )
    Migration.last_down()
  elseif (  parsed_args["db:migration:down"] != nothing )
    Migration.down_by_class_name(parsed_args["db:migration:down"])
  
  elseif (  parsed_args["tasks:list"] == "true" )
    Task.print_all_tasks()
  elseif (  parsed_args["task:run"] != nothing )
    Task.run_task(parsed_args["task:run"])
  elseif ( parsed_args["task:new"] != nothing )
    if ! endswith(parsed_args["task:new"], "_task") parsed_args["task:new"] *= "_task" end
    Task.new(parsed_args, config)

  elseif (  parsed_args["test:run"] == "true" )
    config.app_env = "test"
    Tester.run_all_tests(parsed_args["test:run"], config)
    
  else 
    config.auto_connect = true
    jinnie_app.server = startup(parsed_args) 
    include(abspath("lib/Jinnie/src/interactive_session.jl"))
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
        "--server-port", "-p"
            help = "HTTP server port"
            default = 8000
        "--monitor", "-m"
            help = "true -> monitor files for changes and reload app"
            default = "false"
        "--env", "-e"
            help = "app execution environment [dev|prod|test]"
            default = "dev"
        
        "--db:init"
            help = "true -> create database and core tables"
            default = "false"
        
        "--db:migrations:status"
            help = "true -> list migrations and their status"
            default = "false"
        "--db:migration:new"
            help = "migration_name -> create a new migration, ex: create_table_foos"
        "--db:migration:up"
            help = "true -> run last migration up \n 
                    migration_class_name -> run migration up, ex: CrateTableFoos" 
        "--db:migration:down"
            help = "true -> run last migration down \n 
                    migration_class_name -> run migration down, ex: CreateTableFoos" 
        
        "--tasks:list"
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