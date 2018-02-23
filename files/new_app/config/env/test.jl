using Genie.Configuration

const config =  Settings(
                  output_length       = 100,
                  suppress_output     = false,
                  log_db              = true,
                  log_requests        = true,
                  log_responses       = true,
                  log_router          = true,
                  session_auto_start  = false
                )

ENV["JULIA_REVISE"] = "off"
