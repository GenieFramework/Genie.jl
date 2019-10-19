import Genie
import Logging, LoggingExtras
import Dates

function initialize_logging()
  date_format = "yyyy-mm-dd HH:MM:SS"

  logger =  if Genie.config.log_to_file
              isdir(Genie.LOG_PATH) || mkpath(Genie.LOG_PATH)
              LoggingExtras.DemuxLogger(
                LoggingExtras.FileLogger(joinpath(Genie.LOG_PATH, "$(Genie.config.app_env)-$(Dates.today()).log"), always_flush = true, append = true),
                LoggingExtras.ConsoleLogger(stdout, Genie.config.log_level),
                include_current_global = false
              )
            else
              LoggingExtras.ConsoleLogger(stdout, Genie.config.log_level)
            end

  timestamp_logger(logger) = LoggingExtras.TransformerLogger(logger) do log
    merge(log, (; message = "$(Dates.format(now(), date_format)) $(log.message)"))
  end

  LoggingExtras.DemuxLogger(LoggingExtras.MinLevelLogger(logger, Genie.config.log_level), include_current_global = false) |> timestamp_logger |> global_logger

  nothing
end

@async intialize_logging()