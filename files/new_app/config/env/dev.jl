using Genie.Configuration

const config =  Settings(
                  output_length           = 100,
                  suppress_output         = false,
                  log_db                  = true,
                  log_queries             = true,
                  log_requests            = false,
                  log_responses           = false,
                  log_formatted           = true,
                  log_level               = :debug,
                  log_cache               = true,
                  log_views               = true,
                  assets_path             = "/",
                  cache_duration          = 0,
                  flax_compile_templates  = false,
                  websocket_server        = false,
                  session_auto_start      = false
                )

ENV["JULIA_REVISE"] = "auto"
