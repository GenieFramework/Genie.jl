module Tester

import Revise
import Logging
import Genie, Genie.Util, Genie.Configuration
import Reexport
Reexport.@reexport using HTTP


"""
    setenv() :: Nothing

Switches Genie to the test env for the duration of the current execution.
"""
function setenv(environment = TEST) :: Nothing
  if Genie.config.tests_force_test_env
    Genie.config.app_env = environment
    @warn "Switched app to >> $(uppercase(Genie.config.app_env)) << env"

    Genie.Configuration.env() == environment || error("Could not switch env")
  end

  nothing
end

end