using Genie
using Util
using Lint

type LintFilesTask
end

function description(_::LintFilesTask)
  """
  Lints the files in the indicated dir
  """
end

function run_task!(_::LintFilesTask, parsed_args = Dict())
  dir = joinpath("lib", "Genie", "src")
  for filename in Task(() -> Util.walk_dir(dir))
    lintfile(filename)
  end
end
