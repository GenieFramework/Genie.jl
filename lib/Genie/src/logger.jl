using App
using Logging
using Millboard
using StackTraces

const console_logger = Logger("console_logger")
const file_logger = Logger("file_logger")

function log(message, level = "info")
  message = replace(string(message), "\$", "\\\$")
  
  for l in Genie.config.loggers
    try 
      println()
      eval( parse( "$level($(l.name), \"\"\" " * "\n" * message * " \"\"\")") )
      if level == "err" 
        println()
        show_stacktrace() 
      end
    catch ex
      log("=== CAN'T LOG MESSAGE, INVALID CHARS ===", level)
      @show ex
      show_stacktrace(catch_stacktrace())
    end
  end
end

function log(message, level::Symbol)
  log(message, string(level))
end

function step_dict(dict::Dict)
  d = Dict()
  for (k, v) in dict
    if isa(v, Dict) 
      log_dict(v) 
    else 
      d[k] = truncate_logged_output(v)
    end
  end

  d
end

function log_dict(dict::Dict, level::Symbol = :info)
  log(string(Genie.config.log_formatted ? Millboard.table(dict) : dict), level)
end

function truncate_logged_output(output::AbstractString)
  if length(output) > Genie.config.output_length 
    output = output[1:Genie.config.output_length] * "..."
  end

  output
end

function setup_loggers()
  Logging.configure(console_logger, level = Genie.config.log_level)
  Logging.configure(console_logger, output = STDOUT)

  Logging.configure(file_logger, level = Genie.config.log_level)
  Logging.configure(file_logger, filename = joinpath("log", "$(App.config.app_env).log"))

  push!(Genie.config.loggers, console_logger)
  push!(Genie.config.loggers, file_logger)
end

setup_loggers()