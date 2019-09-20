using Genie
using Logging, LoggingExtras
using Dates

const date_format = "yyyy-mm-dd HH:MM:SS"

const logger =  if Genie.config.log_to_file
                  isdir(Genie.LOG_PATH) || mkpath(Genie.LOG_PATH)
                  DemuxLogger(
                    FileLogger(joinpath(Genie.LOG_PATH, "$(Genie.config.app_env)-$(Dates.today()).log"), always_flush = true, append = true),
                    ConsoleLogger(stdout, Genie.config.log_level),
                    include_current_global = false
                  )
                else
                  ConsoleLogger(stdout, Genie.config.log_level)
                end

timestamp_logger(logger) = TransformerLogger(logger) do log
  merge(log, (; message = "$(Dates.format(now(), date_format)) $(log.message)"))
end

DemuxLogger(MinLevelLogger(logger, Genie.config.log_level), include_current_global = false) |> timestamp_logger |> global_logger