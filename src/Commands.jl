"""
Handles command line arguments for the genie.jl script.
"""
module Commands

using ArgParse, Genie.Configuration, Genie, Genie.Generator, Tester, Toolbox, App, Logger, AppServer
SEARCHLIGHT_ON && eval(:(using SearchLight, Migration))

"""
    execute(config::Settings) :: Void

Runs the requested Genie app command, based on the `args` passed to the script.
"""
function execute(config::Settings) :: Void
  parsed_args = parse_commandline_args()::Dict{String,Any}

  App.config.app_env = ENV["GENIE_ENV"]
  App.config.server_port = parse(Int, parsed_args["server:port"])
  App.config.server_workers_count = (sw = parse(Int, parsed_args["server:workers"])) > 0 ? sw : config.server_workers_count

  if called_command(parsed_args, "db:init")
    SearchLight.create_migrations_table(App.config.db_migrations_table_name)

  elseif parsed_args["app:new"] != nothing
    Genie.REPL.new_app(parsed_args["app:new"])

  elseif parsed_args["model:new"] != nothing
    Genie.Generator.new_model(parsed_args)

  elseif parsed_args["controller:new"] != nothing
    Genie.Generator.new_controller(parsed_args)

  elseif parsed_args["channel:new"] != nothing
    Genie.Generator.new_channel(parsed_args)

  elseif parsed_args["resource:new"] != nothing
    Genie.Generator.new_resource(parsed_args)
    SearchLight.Generator.new_resource(parsed_pargs)

  elseif called_command(parsed_args, "migration:status") || called_command(parsed_args, "migration:list")
    Migration.status()
  elseif parsed_args["migration:new"] != nothing
    Migration.new(parsed_args, config)

  elseif called_command(parsed_args, "migration:allup")
    Migration.all_up()

  elseif called_command(parsed_args, "migration:up")
    Migration.last_up()
  elseif parsed_args["migration:up"] != nothing
    Migration.up_by_module_name(parsed_args["migration:up"])

  elseif called_command(parsed_args, "migration:alldown")
    Migration.all_down()

  elseif called_command(parsed_args, "migration:down")
    Migration.last_down()
  elseif parsed_args["migration:down"] != nothing
    Migration.down_by_module_name(parsed_args["db:migration:down"])

  elseif called_command(parsed_args, "task:list")
    Toolbox.print_tasks()
  elseif parsed_args["task:run"] != nothing
    Toolbox.run_task(check_valid_task!(parsed_args)["task:run"])
  elseif parsed_args["task:new"] != nothing
    Toolbox.new(parsed_args |> check_valid_task!, config)

  elseif called_command(parsed_args, "test:run")
    Tester.run_all_tests(parsed_args["test:run"], config)

  elseif called_command(parsed_args, "websocket:start")
    error("Not implemented!")

  elseif called_command(parsed_args, "s") || called_command(parsed_args, "server:start")
    App.config.run_as_server = true
    AppServer.startup(App.config.server_port)

  end

  nothing
end


"""
    parse_commandline_args() :: Dict{String,Any}

Extracts the command line args passed into the app and returns them as a `Dict`, possibly setting up defaults.
Also, it is used by the ArgParse module to populate the command line help for the app `-h`.
"""
function parse_commandline_args() :: Dict{String,Any}
    settings = ArgParseSettings()

    settings.description = "Genie web framework CLI"
    settings.epilog = "Visit http://genieframework.com for more info"
    settings.version = string(Genie.Configuration.GENIE_VERSION)
    settings.add_version = true

    @add_arg_table settings begin
        "s"
            help = "starts HTTP server"
        "--server:start"
            help = "starts HTTP server"
        "--server:port", "-p"
            help = "HTTP server port"
            default = "8000"
        "--server:workers", "-w"
            help = "Number of workers used by the app -- use any value greater than 1 to overwrite the config"
            default = "1"

        "--websocket:start"
            help = "starts web sockets server"
        "--websocket:port"
            help = "web sockets server port"
            default = "8008"

        "--app:new"
            help = "app_name -> creates a new Genie app"

        "--db:init"
            help = "true -> create database and core tables"
            default = "false"

        "--model:new"
            help = "model_name -> creates a new model, ex: Product"
        "--controller:new"
            help = "controller_name -> creates a new controller, ex: Products"
        "--channel:new"
            help = "channel_name -> creates a new channel, ex: Products"
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
                    migration_module_name -> run migration up, ex: CreateTableFoos"
        "--migration:allup"
            help = "true -> run up all down migrations"
            default = "false"
        "--migration:down"
            help = "true -> run last migration down \n
                    migration_module_name -> run migration down, ex: CreateTableFoos"
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


"""
    called_command(args::Dict, key::String) :: Bool

Checks whether or not a certain command was invoked by looking at the command line args.
"""
function called_command(args::Dict{String,Any}, key::String) :: Bool
    args[key] == "true" || args["s"] == key
end

end
