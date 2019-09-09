using Genie
using Logging, LoggingExtras
using Dates

if Genie.config.log_to_file
  isdir(Genie.LOG_PATH) || mkpath(Genie.LOG_PATH)

  DemuxLogger(
      MinLevelLogger(
        FileLogger(joinpath(Genie.LOG_PATH, "$(Genie.config.app_env)-$(Dates.today()).log"), always_flush = true, append = true), Genie.config.log_level),
        include_current_global = true
  )
else
  ConsoleLogger(stdout, Genie.config.log_level)
end |> global_logger