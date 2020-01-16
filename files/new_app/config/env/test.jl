using Genie.Configuration

const config = Settings(
  server_port                     = 8000,
  server_host                     = "127.0.0.1",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true,
  websockets_server               = false
)

ENV["JULIA_REVISE"] = "off"