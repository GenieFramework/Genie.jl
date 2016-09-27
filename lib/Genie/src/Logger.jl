module Logger

using Lumberjack
using Millboard
using Genie

const colors = Dict{String,Symbol}("info" => :gray, "warn" => :yellow, "debug" => :green, "err" => :red, "error" => :red, "critical" => :magenta)

function log(message, level = "info"; showst::Bool = true)
  println()
  Lumberjack.log(string(level), string(message))
  println()
  # self_log()

  if level == "err" || level == "critical" && showst
    println()
    show_stacktrace()
  end
end
function log(message::String, level::Symbol)
  log(message, level == :err ? "error" : string(level))
end

function self_log(level, message)
  println()
  print_with_color(colors[string(level)], (string(level), " ", string(Dates.now()), "\n")...)
  print_with_color(colors[string(level)], string(message))
  println()
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