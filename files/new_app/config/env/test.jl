using Genie.Configuration

const config =  Settings(
                  cache_duration      = 0,
                  log_cache           = true,
                  log_formatted       = true,
                  log_level           = :debug,
                  log_views           = true,
                  server_handle_static_files = false,
                  session_auto_start  = false,
                  websocket_server    = false
                )

ENV["JULIA_REVISE"] = "off"
