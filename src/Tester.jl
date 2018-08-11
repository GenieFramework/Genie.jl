module Tester

using Genie, Genie.Util, Genie.Configuration, Genie.Logger, SearchLight.Migration


"""
    bootstrap_tests(cmd_args::String, config::Settings) :: Nothing

Sets up testing environment, includes test files, etc.
"""
function bootstrap_tests(cmd_args::String = "", config::Settings = Genie.config, resource::String = "") :: Nothing
  current_env = config.app_env

  set_test_env()

  include(abspath(joinpath(config.test_folder, "test_config.jl")))

  for (path, _, files) in (walkdir(abspath(joinpath(config.test_folder))) |> collect)
    for file_name in files
      isempty(resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
      ! isempty(resource) && startswith(file_name, resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
    end
  end

  Genie.config.app_env = current_env
  Logger.log("Switched app to >> $(uppercase(Genie.config.app_env)) << env", :debug)

  nothing
end


"""
    reset_db() :: Nothing

Prepares the test env DB running all migrations up.
"""
function reset_db() :: Nothing
  Migration.all_down()
  Migration.all_up()

  nothing
end


"""
    run_all_tests(cmd_args::String, config::Settings) :: Nothing

Runs all existing tests.
"""
function run_all_tests(cmd_args::String = "", config::Settings = Genie.config) :: Nothing
  bootstrap_tests(cmd_args, config)

  nothing
end


function run_tests() :: Nothing
  run_all_tests()
end
function run_tests(resource_name::Symbol) :: Nothing
  bootstrap_tests("", Genie.config, string(resource_name) |> lowercase)
end


"""
    set_test_env() :: Nothing

Switches Genie to the test env for the duration of the current execution.
"""
function set_test_env() :: Nothing
  # if ! is_test()
  #   Logger.log("You're attempting to run your test suite outside the TEST environment. This can lead to losing your production or development data, depending on your current/default environment.", :err, showst = false)
  # end
  if Genie.config.tests_force_test_env
    # Logger.log("Automatically switching to TEST environment to aNothing data corruption. If you want to force running your test in a different environment, switch the `tests_force_test_env` variable to `false` in your env's config file.", :debug)
    Genie.config.app_env = TEST
    Logger.log("Switched app to >> $(uppercase(App.config.app_env)) << env", :debug)

    ! is_test() && error("Could not switch env")
  end

  nothing
end

end
