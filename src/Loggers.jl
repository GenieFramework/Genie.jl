"""
Provides logging functionality for Genie apps.
"""
module Loggers

using Memento, Millboard, Dates
using Genie

import Base.log
export log


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
function log(message::Union{String,Symbol,Number,Exception}, level::Union{String,Symbol} = "info") :: Nothing
  message = string(message)
  level = string(level)

  if level == "err" || level == "critical"
    level = "warn"
  elseif level == "debug"
    level = "info"
  else
    level = "info"
  end

  root_logger = try
    Memento.config!(level |> string; fmt="[{date}|{level}]: {msg}")
  catch ex
    Memento.config(string(level))
  end

  try
    if isfile(log_path())
      file_logger = getlogger(@__MODULE__)
      setlevel!(file_logger, Genie.config.log_level |> string)
      push!(file_logger, DefaultHandler(log_path(), DefaultFormatter("[{date}|{level}]: {msg}")))

      Base.invoke(Core.eval(@__MODULE__, Meta.parse("Memento.$level")), Tuple{typeof(file_logger),typeof(message)}, file_logger, message)
    else
      Base.invoke(Core.eval(@__MODULE__, Meta.parse("Memento.$level")), Tuple{typeof(root_logger),typeof(message)}, root_logger, message)
    end
  catch ex
    println(string(ex))
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
    "$(joinpath(path, Genie.config.app_env)).log"
  catch ex
    string(ex)
    println("...")
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
