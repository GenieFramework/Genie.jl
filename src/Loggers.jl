"""
Provides logging functionality.
"""
module Loggers

using Millboard, Dates, MiniLogging
using Genie

import Base.log
export log


"""
Map Genie log levels to MiniLogging levels
"""
const LOG_LEVEL_MAPPING = Dict(
  :debug    => MiniLogging.DEBUG,
  :info     => MiniLogging.INFO,
  :warn     => MiniLogging.WARN,
  :error    => MiniLogging.ERROR,
  :err      => MiniLogging.ERROR,
  :critical => MiniLogging.CRITICAL
)


"""
    log(message::Union{String,Symbol,Number,Exception}, level::Union{String,Symbol} = :debug; showst = false) :: Nothing

Logs `message` to all registered logger, taking into account the log `level`.
"""
function log(message::Union{String,Symbol,Number,Exception}, level::Union{String,Symbol} = :debug; showst = false) :: Nothing
  message = string(" ", message)
  level = string(level)

  try
    if isempty(get_logger().handlers)
      if Genie.config.log_to_file
        basic_config(LOG_LEVEL_MAPPING[Genie.config.log_level], log_path()) # file logger
        push!(get_logger().handlers, MiniLogging.Handler(stderr, "%Y-%m-%d %H:%M:%S")) # console logger
      else
        basic_config(LOG_LEVEL_MAPPING[Genie.config.log_level], date_format = "%Y-%m-%d %H:%M:%S")
      end
    end
  catch ex
    basic_config(LOG_LEVEL_MAPPING[Genie.config.log_level], date_format = "%Y-%m-%d %H:%M:%S")
  end

  loggo = get_logger()

  if level == "debug"
    MiniLogging.@debug(loggo, message)
  elseif level == "info"
    MiniLogging.@info(loggo, message)
  elseif level == "warn"
    MiniLogging.@warn(loggo, message)
  elseif level == "error" || level == "err"
    MiniLogging.@error(loggo, message)
  elseif level == "critical"
    MiniLogging.@critical(loggo, message)
  else
    MiniLogging.@debug(loggo, message)
  end

  if (level == "error") && showst
    println()
    stacktrace()
  end

  nothing
end


function log_path()
  "$(joinpath(Genie.LOG_PATH, ENV["GENIE_ENV"])).log"
end
function log_path!()
  initlogfile()
  log_path()
end


function initlogfile()
	lp = log_path()
	Base.@info "Logging to file at $(abspath(lp)) \n"
  dirname(lp) |> mkpath
	touch(lp)
end

end
