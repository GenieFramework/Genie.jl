using Genie.Configuration, Logging

const config = Settings(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_cache                       = false,
  log_formatted                   = false,
  log_level                       = Logging.Error,
  log_views                       = false,
  log_to_file                     = true,
  server_handle_static_files      = false
)

ENV["JULIA_REVISE"] = "off"