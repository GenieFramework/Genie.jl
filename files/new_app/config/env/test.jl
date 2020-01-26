using Genie.Configuration, Logging

const config = Settings(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true
)

ENV["JULIA_REVISE"] = "off"