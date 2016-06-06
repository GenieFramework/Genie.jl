using Configuration
using Logging 

const config = Config(output_length = 100, 
                      supress_output = false, 
                      log_db = false, 
                      log_requests = true, 
                      log_responses = true, 
                      log_router = false, 
                      log_formatted = false, 
                      log_level = Logging.ERROR)

export config