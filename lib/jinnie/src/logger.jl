function log(message, level="info")
  message = string(message)
  Logging.info(message)
 
  for l in loggers
    eval(parse("$level($(l.name), " * message * ")"))
  end
end

function logorhea(message, level, return_value)
  log(message, level)

  return return_value
end