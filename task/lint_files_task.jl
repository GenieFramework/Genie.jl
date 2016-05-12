using Genie
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
  for filename in Task(() -> walk_dir(dir))
    println(filename)
    lintfile(filename)
    println()
  end
end
