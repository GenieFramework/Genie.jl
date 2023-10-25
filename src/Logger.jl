module Logger

using Genie
using Logging, LoggingExtras
import Dates

"""
Collection of custom user defined handlers that will be called when a log message is received.

# Example
```julia
julia> f(args...) = println(args...)

julia> push!(Logger.HANDLERS, f)

julia> @info "hello"
[ Info: 2023-10-25 13:36:15 hello
Info2023-10-25 13:36:15 helloMainREPL[5]Main_0f6a5e07REPL[5]1
```
"""
const HANDLERS = Function[]

function timestamp_logger(logger)
  date_format = Genie.config.log_date_format

  LoggingExtras.TransformerLogger(logger) do log
    merge(log, (; message = "$(Dates.format(Dates.now(), date_format)) $(log.message)"))
  end
end

function default_log_name()
  "$(Genie.config.app_env)-$(Dates.today()).log"
end

function initialize_logging(; log_name = default_log_name())
  logger =  if Genie.config.log_to_file
              isdir(Genie.config.path_log) || mkpath(Genie.config.path_log)
              LoggingExtras.TeeLogger(
                LoggingExtras.FileLogger(joinpath(Genie.config.path_log, log_name), always_flush = true, append = true),
                Logging.ConsoleLogger(stdout, Genie.config.log_level)
              )
            else
              Logging.ConsoleLogger(stdout, Genie.config.log_level)
            end
  logger = LoggingExtras.TeeLogger(
    logger,
    GenieLogger() do lvl, msg, _mod, group, id, file, line
      for handler in HANDLERS
        try
          handler(lvl, msg, _mod, group, id, file, line)
        catch
        end
      end
    end
  )

  LoggingExtras.TeeLogger(LoggingExtras.MinLevelLogger(logger, Genie.config.log_level)) |> timestamp_logger |> global_logger

  nothing
end

### custom logger

"""
GenieLogger is a custom logger that allows you to pass a function that will be called with the log message, level, module, group, id, file and line.

# Example
```julia
l = Genie.Logger.GenieLogger() do lvl, msg, _mod, group, id, file, line
  uppercase(msg) |> println
end

with_logger(l) do
  @info "hello"
  @warn "watch out"
  @error "oh noh"
end
```
"""
struct GenieLogger <: Logging.AbstractLogger
  action::Function
  io::IO
end

GenieLogger(action::Function) = GenieLogger(action, stderr)

Logging.min_enabled_level(logger::GenieLogger) = Logging.BelowMinLevel
Logging.shouldlog(logger::GenieLogger, level, _module, group, id) = true
Logging.catch_exceptions(logger::GenieLogger) = true

function Logging.handle_message(logger::GenieLogger, lvl, msg, _mod, group, id, file, line; kwargs...)
  logger.action(lvl, msg, _mod, group, id, file, line; kwargs...)
  nothing
end

end