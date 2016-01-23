function log(message, level="info")
  message = string(message)
  # eval(parse("Logging.$level($message)")) -- default console logging is broken due to Logging pkg
 
  for l in loggers
    eval( parse( "$level($(l.name), " * message * ")" ) )
  end
end