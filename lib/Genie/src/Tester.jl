module Tester

using Genie
using Util
using Migration

function bootstrap_tests(cmd_args::AbstractString, config::Genie.Config)
  include(abspath(joinpath(config.test_folder, "test_config.jl")))

  for file_name in Task(() -> Util.walk_dir(abspath(joinpath(config.test_folder))))
    if ( endswith(file_name, "_test.jl") )
      include(file_name)
    end
  end
end

function reset_db(; supress_output::Bool = true)
  Migration.all_down()
  Migration.all_up()
end

function run_all_tests(cmd_args::AbstractString, config::Genie.Config)
  bootstrap_tests(cmd_args, config)
end

end