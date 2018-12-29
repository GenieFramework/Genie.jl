"""
Provides logging functionality for Genie apps.
"""
module Loggers

using Dates
using Genie
using Logging

import Base.log
export log, initialize_logging

global _isloggingconfigured = false

function _default_logcolor(level)
    level < Logging.Info  ? Base.debug_color() :
    level < Logging.Warn  ? Base.info_color()  :
    level < Logging.Error ? Base.warn_color()  :
                    Base.error_color()
end
"""
  Customized logging format function.
"""
function metafmt(level, _module, group, id, file, line)
  # Set the prefix and suffix for the logging message here.
  color = _default_logcolor(level)
  prefix = "[$(string(now()))] $(level == Logging.Warn ? "Warning" : string(level)):"
  suffix = ""
  Logging.Info <= level < Logging.Warn && return color, prefix, suffix
  _module !== nothing && (suffix *= "$(_module)")
  if file !== nothing
    _module !== nothing && (suffix *= " ")
    suffix *= Base.contractuser(file)
    if line !== nothing
      suffix *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
    end
  end
  !isempty(suffix) && (suffix = "@ " * suffix)
  return color, prefix, suffix
end

function _logstringtologgingenum(level::Union{String,Symbol})::Logging.LogLevel
  level = string(level)
  level == "debug" && return Logging.Debug
  level == "info" && return Logging.Info
  level == "warn" && return Logging.Warn
  level == "error" && return Logging.Error
  # Default
  return Logging.Info
end

"""
Initialize the logging.
"""
function initialize_logging()::Nothing
  global _isloggingconfigured
  if !_isloggingconfigured
    @info "Configuring a global logger to log level: '$(Genie.config.log_level)'. Message after this will be filtered, you can change this in your config file for your environment."
    # Default to stderr.
    #TODO: Can set to write to a stream here with the first parameter if file logging should be done.
    # Personally I just keep everything working on console so that console loggers like Splunk and Kibana can just capture them
    consoleLogger = ConsoleLogger(stderr, _logstringtologgingenum(Genie.config.log_level), meta_formatter=metafmt)
    global_logger(consoleLogger)
    _isloggingconfigured = true
  end
  return nothing
end

"""
    log(message, level = "info"; showst::Bool = true) :: Nothing
    log(message::Any, level::Any = "info"; showst::Bool = false) :: Nothing
    log(message::String, level::Symbol) :: Nothing

Logs `message` to all configured logs (STDOUT, FILE, etc) by delegating to `Lumberjack`.
Supported values for `level` are "info", "warn", "debug", "error".
If `level` is `error` or `critical` it will also dump the stacktrace onto STDOUT.

# Examples
```julia
```
"""
function log(message::Union{String,Symbol,Number,Exception}, level::Union{String,Symbol} = "info") :: Nothing
  message = string(message)
  level = string(level)

  # Just a check in case it wasn't initialized.
  global _isloggingconfigured
  if !_isloggingconfigured
    initializeLogging()
  end

  try
    level == "debug" && @debug message
    level == "info" && @info message
    level == "warn" && @warn message
    (level == "error" || level == "err" || level == "critical") && @error message
  catch ex
    @info string(ex)
  end

  nothing
end


"""
    truncate_logged_output(output::String) :: String

Truncates (shortens) output based on `output_length` settings and appends "..." -- to be used for limiting the output length when logging.

# Examples
```julia
julia> Genie.config.output_length
100

julia> Genie.config.output_length = 10
10

julia> Loggers.truncate_logged_output("abc " ^ 10)
"abc abc ab..."
```
"""
function truncate_logged_output(output::String) :: String
  length(output) > Genie.config.output_length && output[1:Genie.config.output_length] * "..."
end


function log_path(path = Genie.LOG_PATH) :: String
  try
    "$(joinpath(path, haskey(ENV, "GENIE_ENV") ? ENV["GENIE_ENV"] : "dev")).log"
  catch ex
    string(ex) |> println
    # println("...")
    "$(joinpath(path, "dev")).log"
  end
end
function log_path!(path = Genie.LOG_PATH) :: String
  if ! isfile(log_path(path))
    mkpath(path)
    touch(log_path(path))
  end

  log_path(path)
end


"""
    empty_log_queue() :: Vector{Tuple{String,Symbol}}

The Genie log queue is used to push log messages in the early phases of framework bootstrap,
when the logger itself is not available. Once the logger is ready, the queue is emptied and the
messages are logged.
Automatically invoked.
"""
function empty_log_queue() :: Nothing
  for log_message in Genie.GENIE_LOG_QUEUE
    log(log_message...)
  end

  empty!(Genie.GENIE_LOG_QUEUE)

  nothing
end


"""
    macro location()

Provides a macro that injects the FILE and the LINE where the logger was invoked.
"""
macro location()
  :(log(" in $(@__FILE__):$(@__LINE__)", :err))
end

# setup_loggers()
# empty_log_queue()

end
