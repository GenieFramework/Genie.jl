module Logger

using Lumberjack, Millboard, Genie

# color mappings for logging levels -- to be used in STDOUT printing
const colors = Dict{String,Symbol}("info" => :gray, "warn" => :yellow, "debug" => :green, "err" => :red, "error" => :red, "critical" => :magenta)

"""
    log(message, level = "info"; showst::Bool = true) :: Void
    log(message::String, level::Symbol) :: Void

Logs `message` to all configured logs (STDOUT, FILE, etc) by delegating to `Lumberjack`.
Supported values for `level` are "info", "warn", "debug", "err" / "error", "critical".
If `level` is `error` or `critical` it will also dump the stacktrace onto STDOUT.

# Examples
```julia
julia> Logger.log("hello")

2016-12-21T18:38:09.105 - info: hello


julia> Logger.log("hello", "warn")

2016-12-21T18:38:22.461 - warn: hello


julia> Logger.log("hello", "debug")

2016-12-21T18:38:32.292 - debug: hello


julia> Logger.log("hello", "err")

2016-12-21T18:38:38.403 - err: hello
```
"""
function log(message, level::String = "info"; showst::Bool = true) :: Void
  level == "err" && (level = "error")

  println()
  Lumberjack.log(string(level), string(message))
  println()

  if (level == "critical" || level == "error") && showst
    println()
    stacktrace()
  end

  nothing
end
function log(message::String, level::Symbol) :: Void
  log(message, level == :err ? "error" : string(level))
end


"""
    self_log(message, level::Union{String,Symbol}) :: Void

Basic logging function that does not rely on external logging modules (such as `Lumberjack`).

# Examples
```julia
julia> Logger.self_log("hello", :err)

err 2016-12-21T18:49:00.286
hello

julia> Logger.self_log("hello", :info)

info 2016-12-21T18:49:05.068
hello

julia> Logger.self_log("hello", :debug)

debug 2016-12-21T18:49:11.123
hello
```
"""
function self_log(message, level::Union{String,Symbol}) :: Void
  println()
  print_with_color(colors[string(level)], (string(level), " ", string(Dates.now()), "\n")...)
  print_with_color(colors[string(level)], string(message))
  println()

  nothing
end


"""

"""
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
  configure(; modes=["debug", "info", "notice", "warn", "err", "critical", "alert", "emerg"])
  add_truck(LumberjackTruck(STDOUT, nothing, Dict{Any,Any}(:is_colorized => true)), "console")
  add_truck(LumberjackTruck("$(joinpath(Genie.LOG_PATH, Genie.config.app_env)).log", nothing, Dict{Any,Any}(:is_colorized => true)), "file-logger")

  true
end

function empty_log_queue() :: Vector{Tuple{String,Symbol}}
  for log_message in Genie.GENIE_LOG_QUEUE
    log(log_message...)
  end

  empty!(Genie.GENIE_LOG_QUEUE)
end

macro location()
  :(Logger.log(" in $(@__FILE__):$(@__LINE__)", :err))
end

setup_loggers()
empty_log_queue()

end
