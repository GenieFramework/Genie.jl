using Configuration

export config

const config =  Settings(
                  output_length     = 100,
                  suppress_output   = false,
                  log_db            = true,
                  log_queries       = true,
                  log_requests      = true,
                  log_responses     = true,
                  log_router        = false,
                  log_formatted     = true,
                  log_level         = "debug",
                  log_cache         = true,
                  assets_path       = "/",
                  cache_duration    = 0,
                  pagination_default_items_per_page = 25
                )
