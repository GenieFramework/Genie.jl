Logger.log(""" 
              2018-04-19:
                            config.app_is_api is deprecated and will be removed in a future update.
                            Please delete all references to it, including in config/app.jl.
                            Failing to remove all references to config.app_is_api will cause the app to crash.
                            """, :warn)
