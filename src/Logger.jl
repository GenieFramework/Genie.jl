module Logger

using Genie
using Logging, LoggingExtras
import Dates

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

  LoggingExtras.TeeLogger(LoggingExtras.MinLevelLogger(logger, Genie.config.log_level)) |> timestamp_logger |> global_logger

  nothing
end

end