"""
Provides logging functionality for Genie apps.
"""
module Logger

using Memento, Millboard, Dates
using Genie


const LOGGERS = Dict{Symbol,Memento.Logger}()


"""
    log(message, level = "info"; showst::Bool = true) :: Nothing
    log(message::Any, level::Any = "info"; showst::Bool = false) :: Nothing
    log(message::String, level::Symbol) :: Nothing

Logs `message` to all configured logs (STDOUT, FILE, etc) by delegating to `Lumberjack`.
Supported values for `level` are "info", "warn", "debug", "err" / "error", "critical".
If `level` is `error` or `critical` it will also dump the stacktrace onto STDOUT.

# Examples
```julia
```
"""
function log(message, level::Union{String,Symbol} = "info"; showst = false) :: Nothing
  message = string(message)
  level = string(level)
  level == "err" && (level = "error")

  for (logger_name, logger) in LOGGERS
    Core.eval(@__MODULE__, Meta.parse("$level($logger, \"$message\")"))
  end

  if (level == "error") && showst
    println()
    stacktrace()
  end

  nothing
end
function log(message::String, level::Union{String,Symbol}; showst::Bool = false) :: Nothing
  log(message, level == :err ? "error" : string(level), showst = showst)
end


"""
    truncate_logged_output(output::AbstractString) :: String

Truncates (shortens) output based on `output_length` settings and appends "..." -- to be used for limiting the output length when logging.

# Examples
```julia
julia> Genie.config.output_length
100

julia> Genie.config.output_length = 10
10

julia> Logger.truncate_logged_output("abc " ^ 10)
"abc abc ab..."
```
"""
function truncate_logged_output(output::String) :: String
  length(output) > Genie.config.output_length && output[1:Genie.config.output_length] * "..."
end


"""
    setup_loggers() :: Bool

Sets up default app loggers (STDOUT and per env file loggers) defferring to the `Lumberjack` module.
Automatically invoked.
"""
function setup_loggers() :: Bool
  push!(LOGGERS, :stdout_logger => Memento.config!(Genie.config.log_level |> string; fmt="[{date}|{level}]: {msg}"))

  file_logger = getlogger(@__MODULE__)
  setlevel!(file_logger, Genie.config.log_level |> string)
  push!(file_logger, DefaultHandler("$(joinpath(Genie.LOG_PATH, Genie.config.app_env)).log",
                                    DefaultFormatter("[{date}|{level}]: {msg}")))
  push!(LOGGERS, :file_logger => file_logger)

  true
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
  :(Logger.log(" in $(@__FILE__):$(@__LINE__)", :err))
end

setup_loggers()
empty_log_queue()

end
