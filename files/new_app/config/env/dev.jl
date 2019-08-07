using Genie.Configuration

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

ENV["JULIA_REVISE"] = "auto"
