using Genie.Configuration

const config = Settings(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Debug,
  log_to_file                     = false,
  server_handle_static_files      = true,
  websockets_server               = false
)

ENV["JULIA_REVISE"] = "auto"