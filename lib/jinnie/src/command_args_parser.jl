using ArgParse

function parse_commandline_args()
    s = ArgParseSettings()

    @add_arg_table s begin
        "s"
            help = "starts HTTP server"
        "--server-port", "-p"
            help = "HTTP server port"
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
    end

    return parse_args(s)
end