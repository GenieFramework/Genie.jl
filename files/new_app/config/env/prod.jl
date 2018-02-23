using Genie.Configuration

const config =  Settings(
                  output_length       = 0,
                  suppress_output     = false,
                  log_db              = false,
                  log_queries         = false,
                  log_requests        = false,
                  log_responses       = false,
                  log_router          = false,
                  log_formatted       = false,
                  log_cache           = false,
                  log_level           = "error",
                  log_verbosity       = LOG_LEVEL_VERBOSITY_MINIMAL,
                  assets_path         = "/",
                  cache_duration      = 1_000,
                  session_auto_start  = false
                )

ENV["JULIA_REVISE"] = "off"
