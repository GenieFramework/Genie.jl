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
        "--monitor"
            help = "=true -> monitor files for changes and reload app"
            default = false
        "--env", "-e"
            help = "app execution environment [dev|prod|test]"
            default = "dev"
        "--db:init"
            help = "=true -> create database and core tables"
        "--db:migrations:status"
            help = "=true -> list migrations and their status"
        "--db:migration:new"
            help = "=migration_name -> create a new migration, ex: create_table_foos"
        "--db:migration:up"
            help = "=true -> run last migration up \n 
                    =migration_class_name -> run migration up, ex: CrateTableFoos" 
        "--db:migration:down"
            help = "=true -> run last migration down \n 
                    =migration_class_name -> run migration down, ex: CreateTableFoos" 
        "--tasks:list"
            help = "=true -> list tasks" 
        "--task:new"
            help = "=task_name -> create a new task, ex: sync_files_task"
        "--task:run"
            help = "=task_name -> run task" 
    end

    return parse_args(s)
end