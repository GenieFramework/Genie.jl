module Tester

using Genie, Genie.Util, Genie.Configuration, Genie.Loggers


"""
    bootstrap_tests(cmd_args::String, config::Settings) :: Nothing

Sets up testing environment, includes test files, etc.
"""
function bootstrap_tests(cmd_args::String = "", config::Settings = Genie.config, resource::String = "") :: Nothing
  current_env = config.app_env

  set_test_env()

  include(abspath(joinpath(Genie.TEST_PATH, "test_config.jl")))

  for (path, _, files) in (walkdir(abspath(joinpath(Genie.TEST_PATH))) |> collect)
    for file_name in files
      isempty(resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
      ! isempty(resource) && startswith(file_name, resource) && endswith(file_name, "_test.jl") && include(joinpath(path, file_name))
    end
  end

  Genie.config.app_env = current_env
  log("Switched app to >> $(uppercase(Genie.config.app_env)) << env", :debug)

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
  if Genie.config.tests_force_test_env
    Genie.config.app_env = TEST
    log("Switched app to >> $(uppercase(App.config.app_env)) << env", :debug)

    ! istest() && error("Could not switch env")
  end

  nothing
end

end
