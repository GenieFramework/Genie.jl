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
            help = "monitor files for changes and reload app"
            default = false
        "--env", "-e"
            help = "app execution environment"
            default = "dev"
        "--db:init"
            help = "Create database"
        "--db:migrations:status"
            help = "List migrations and their status"
        "--db:migration:new"
            help = "Create a new migration"
        "--db:migration:up"
            help = "Run last migration up"
        "--db:migration:down"
            help = "Run last migration down"
    end

    return parse_args(s)
end