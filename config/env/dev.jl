using Configuration
using Logging

const config = Config(
                      output_length     = 100,
                      suppress_output   = false,
                      log_db            = true,
                      log_requests      = true,
                      log_responses     = true,
                      log_router        = true,
                      log_formatted     = true,
                      log_level         = Logging.DEBUG,
                      assets_path       = "/"
                    )

export config