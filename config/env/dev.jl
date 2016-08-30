using Configuration
using Logging

const config = Config(
                      output_length     = 100,
                      suppress_output   = false,
                      log_db            = true,
                      log_requests      = true,
                      log_responses     = true,
                      log_router        = false,
                      log_formatted     = true,
                      log_level         = Logging.DEBUG,
                      assets_path       = "/",
                      cache_ejl         = false,
                    )

export config