using Genie.Configuration

const config =  Settings(
                  assets_path         = "/",
                  cache_duration      = 1_000,
                  log_cache           = false,
                  log_formatted       = false,
                  log_level           = :error,
                  log_router          = false,
                  log_verbosity       = LOG_LEVEL_VERBOSITY_MINIMAL,
                  log_views           = false,
                  log_to_file         = true, 
                  output_length       = 0,
                  server_handle_static_files = false,
                  session_auto_start  = false,
                  suppress_output     = false,
                  websocket_server    = false
                )

ENV["JULIA_REVISE"] = "off"
