module Tester

using Genie, App, Util, Genie.Configuration, Logger
SEARCHLIGHT_ON && eval(:(using Migration))


"""
    bootstrap_tests(cmd_args::String, config::Settings) :: Void

Sets up testing environment, includes test files, etc.
"""
function bootstrap_tests(cmd_args::String = "", config::Settings = App.config, resource::String = "") :: Void
  current_env = config.app_env

  set_test_env()

  include(abspath(joinpath(config.test_folder, "test_config.jl")))

  for (path, _, files) in (walkdir(abspath(joinpath(config.test_folder))) |> collect)
    for file_name in files
      isempty(resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
      ! isempty(resource) && startswith(file_name, resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
    end
  end

  App.config.app_env = current_env
  Logger.log("Switched app to >> $(uppercase(App.config.app_env)) << env", :debug)

  nothing
end


"""
    reset_db() :: Void

Prepares the test env DB running all migrations up.
"""
function reset_db() :: Void
  Migration.all_down()
  Migration.all_up()

  nothing
end


"""
    run_all_tests(cmd_args::String, config::Settings) :: Void

Runs all existing tests.
"""
function run_all_tests(cmd_args::String = "", config::Settings = App.config) :: Void
  bootstrap_tests(cmd_args, config)

  nothing
end


function run_tests() :: Void
  run_all_tests()
end
function run_tests(resource_name::Symbol) :: Void
  bootstrap_tests("", App.config, string(resource_name) |> lowercase)
end


"""
    set_test_env() :: Void

Switches Genie to the test env for the duration of the current execution.
"""
function set_test_env() :: Void
  # if ! is_test()
  #   Logger.log("You're attempting to run your test suite outside the TEST environment. This can lead to losing your production or development data, depending on your current/default environment.", :err, showst = false)
  # end
  if App.config.tests_force_test_env
    # Logger.log("Automatically switching to TEST environment to avoid data corruption. If you want to force running your test in a different environment, switch the `tests_force_test_env` variable to `false` in your env's config file.", :debug)
    App.config.app_env = TEST
    Logger.log("Switched app to >> $(uppercase(App.config.app_env)) << env", :debug)

    ! is_test() && error("Could not switch env")
  end

  nothing
end

end
