module Commands
using ArgParse, Configuration, Genie, Database, Generator, Tester, Toolbox, App, Migration, Logger

function called_command(args, key)
    args[key] == "true" || args["s"] == key
end

function execute(config::Config)
  parsed_args = parse_commandline_args()::Dict{AbstractString,Any}

  config.app_env = ENV["GENIE_ENV"]
  config.server_port = parse(Int, parsed_args["server:port"])
  config.server_workers_count = (sw = parse(Int, parsed_args["server:workers"])) > 0 ? sw : config.server_workers_count

  if called_command(parsed_args, "db:init")
    Database.create_database()
    Database.create_migrations_table()

  elseif parsed_args["model:new"] != nothing
    Generator.new_model(parsed_args, config)

  elseif parsed_args["resource:new"] != nothing
    Generator.new_resource(parsed_args, config)

  elseif called_command(parsed_args, "migration:status") || called_command(parsed_args, "migration:list")
    Migration.status()
  elseif parsed_args["migration:new"] != nothing
    Migration.new(parsed_args, config)

  elseif called_command(parsed_args, "migration:allup")
    Migration.all_up()

  elseif called_command(parsed_args, "migration:up")
    Migration.last_up()
  elseif parsed_args["migration:up"] != nothing
    Migration.up_by_class_name(parsed_args["migration:up"])

  elseif called_command(parsed_args, "migration:alldown")
    Migration.all_down()

  elseif called_command(parsed_args, "migration:down")
    Migration.last_down()
  elseif parsed_args["migration:down"] != nothing
    Migration.down_by_class_name(parsed_args["db:migration:down"])

  elseif called_command(parsed_args, "task:list")
    Toolbox.print_all_tasks()
  elseif parsed_args["task:run"] != nothing
    Toolbox.run_task(check_valid_task!(parsed_args)["task:run"])
  elseif parsed_args["task:new"] != nothing
    Toolbox.new(parsed_args |> check_valid_task!, config)

  elseif called_command(parsed_args, "test:run")
    Tester.run_all_tests(parsed_args["test:run"], config)

  elseif called_command(parsed_args, "s")
    Genie.startup(parsed_args)

  end
end

function check_valid_task!(parsed_args::Dict{String,Any})
  haskey(parsed_args, "task:new") && isa(parsed_args["task:new"], String) && ! endswith(parsed_args["task:new"], "Task") && (parsed_args["task:new"] *= "Task")
  haskey(parsed_args, "task:run") && isa(parsed_args["task:run"], String) &&! endswith(parsed_args["task:run"], "Task") && (parsed_args["task:run"] *= "Task")
  parsed_args
end

function parse_commandline_args()
    settings = ArgParseSettings()

    settings.description = "Genie web framework CLI"
    settings.epilog = "Visit http://genieframework.com for more info"
    settings.version = "0.6.1"
    settings.add_version = true

    @add_arg_table settings begin
        "s"
            help = "starts HTTP server"
        "--server:port", "-p"
            help = "HTTP server port"
            default = "8000"
        "--server:workers", "-w"
            help = "Number of workers used by the app -- use any value greater than 1 to overwrite the config"
            default = "1"

        "--db:init"
            help = "true -> create database and core tables"
            default = "false"

        "--model:new"
            help = "model_name -> creates a new model, ex: Product"

        "--resource:new"
            help = "resource_name -> creates a new resource folder with all its files, ex: products"

        "--migration:status"
              help = "true -> list migrations and their status"
              default = "false"
        "--migration:list"
            help = "alias for migration:status"
            default = "false"
        "--migration:new"
            help = "migration_name -> create a new migration, ex: create_table_foos"
        "--migration:up"
            help = "true -> run last migration up \n
                    migration_class_name -> run migration up, ex: CreateTableFoos"
        "--migration:allup"
            help = "true -> run up all down migrations"
            default = "false"
        "--migration:down"
            help = "true -> run last migration down \n
                    migration_class_name -> run migration down, ex: CreateTableFoos"
        "--migration:alldown"
            help = "true -> run down all up migrations"
            default = "false"

        "--task:list"
            help = "true -> list tasks"
            default = "false"
        "--task:new"
            help = "task_name -> create a new task, ex: SyncFiles"
        "--task:run"
            help = "task_name -> run task"

        "--test:run"
            help = "true -> run tests"
            default = "false"
    end

    parse_args(settings)
end

end