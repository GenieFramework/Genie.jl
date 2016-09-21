module Logger

using Lumberjack
using Millboard
using StackTraces
using Genie

function log(message, level = "info"; showst::Bool = true)
  println()
  Lumberjack.log(string(level), string(message))

  if level == "err" || level == "critical" && showst
    println()
    show_stacktrace()
  end
end
function log(message::AbstractString, level::Symbol)
  log(message, level == :err ? "error" : string(level))
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
  configure(; modes=["debug", "info", "notice", "warn", "err", "critical", "alert", "emerg"])
  add_truck(LumberjackTruck(STDOUT, nothing, Dict{Any,Any}(:is_colorized => true)), "console")
  add_truck(LumberjackTruck("$(Genie.config.app_env).log", nothing, Dict{Any,Any}(:is_colorized => true)), "file-logger")

  true
end

setup_loggers()

end