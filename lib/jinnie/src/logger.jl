using Logging

const console_logger = Logger("console_logger")
const file_logger = Logger("file_logger")

function log(message, level="info")
  message = string(message)
  # eval(parse("Logging.$level($message)")) -- default console logging is broken due to Logging pkg
 
  for l in config.loggers
    eval( parse( "$level($(l.name), \"\"\" " * message * " \"\"\" )" ) )
  end
end

function setup_loggers()
  Logging.configure(console_logger, level = DEBUG)
  Logging.configure(console_logger, output = STDOUT)

  Logging.configure(file_logger, level = DEBUG)
  Logging.configure(file_logger, filename = joinpath("log", "jinnie.log"))

  push!(config.loggers, console_logger)
  push!(config.loggers, file_logger)
end

setup_loggers()