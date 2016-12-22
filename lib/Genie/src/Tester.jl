module Tester
using Genie, App, Util, Migration, Configuration, Logger

function bootstrap_tests(cmd_args::AbstractString, config::Settings)
  set_test_env()

  include(abspath(joinpath(config.test_folder, "test_config.jl")))

  for file_name in Task(() -> Util.walk_dir(abspath(joinpath(config.test_folder))))
    if ( endswith(file_name, "_test.jl") )
      include(file_name)
    end
  end
end

function reset_db()
  Migration.all_down()
  Migration.all_up()
end

function run_all_tests(cmd_args::AbstractString, config::Settings)
  bootstrap_tests(cmd_args, config)
end

function set_test_env()
  if ! is_test()
    Logger.log("You're attempting to run your test suite outside the TEST environment. This can lead to losing your production or development data, depending on your current/default environment.", :err, showst = false)
  end
  if Genie.config.tests_force_test_env
    Logger.log("Automatically switching to TEST environment to avoid data corruption. If you want to force running your test in a different environment, switch the `tests_force_test_env` variable to `false` in your env's config file.", :debug)
    Genie.config.app_env = TEST
    Logger.log("Switched Genie to >> $(uppercase(Genie.config.app_env)) << env", :debug)

    ! is_test() && error("Could not switch env")
  end
end

end
