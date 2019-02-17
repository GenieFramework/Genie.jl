using Genie.Configuration

const config =  Settings(
                  assets_path         = "/",
                  cache_duration      = 0,
                  log_cache           = true,
                  log_formatted       = true,
                  log_level           = :debug,
                  log_router          = false,
                  log_verbosity       = LOG_LEVEL_VERBOSITY_VERBOSE,
                  log_views           = true,
                  output_length       = 100,
                  server_handle_static_files = false,
                  session_auto_start  = false,
                  suppress_output     = false,
                  websocket_server    = false
                )

ENV["JULIA_REVISE"] = "off"
