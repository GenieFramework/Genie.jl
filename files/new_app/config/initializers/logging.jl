import Genie
import Logging, LoggingExtras
import Dates

function initialize_logging()
  date_format = "yyyy-mm-dd HH:MM:SS"

  logger =  if Genie.config.log_to_file
              isdir(Genie.config.path_log) || mkpath(Genie.config.path_log)
              LoggingExtras.TeeLogger(
                LoggingExtras.FileLogger(joinpath(Genie.config.path_log, "$(Genie.config.app_env)-$(Dates.today()).log"), always_flush = true, append = true),
                Logging.ConsoleLogger(stdout, Genie.config.log_level)
              )
            else
              Logging.ConsoleLogger(stdout, Genie.config.log_level)
            end

  timestamp_logger(logger) = LoggingExtras.TransformerLogger(logger) do log
    merge(log, (; message = "$(Dates.format(Dates.now(), date_format)) $(log.message)"))
  end

  LoggingExtras.TeeLogger(LoggingExtras.MinLevelLogger(logger, Genie.config.log_level)) |> timestamp_logger |> global_logger

  nothing
end

initialize_logging()