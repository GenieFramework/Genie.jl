using Genie.Configuration, Logging

const config =  Settings(
                  cache_duration      = 0,
                  log_cache           = true,
                  log_formatted       = true,
                  log_level           = :debug,
                  log_views           = true,
                  log_to_file         = false,
                  server_handle_static_files = true,
                  session_auto_start  = false,
                  websocket_server    = false,
                  flax_autoregister_webcomponents = true
                )

global_logger(ConsoleLogger(stdout, Logging.Debug))

ENV["JULIA_REVISE"] = "auto"
