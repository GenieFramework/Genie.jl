using Genie.Configuration

const config =  Settings(
                  cache_duration      = 1_000,
                  log_cache           = false,
                  log_formatted       = false,
                  log_level           = :error,
                  log_views           = false,
                  log_to_file         = true,
                  server_handle_static_files = false,
                  session_auto_start  = false,
                  websocket_server    = false,
                  flax_autoregister_webcomponents = false
                )

ENV["JULIA_REVISE"] = "off"
