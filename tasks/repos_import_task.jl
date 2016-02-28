using GitHub
using Jinnie
using Database

type Repos_Import_Task
end

function description(_::Repos_Import_Task)
  """
  Imports list of repos (name, URL) in database, using local package information and the GitHub pkg
  """
end

function run_task!(_::Repos_Import_Task, parsed_args = Dict())
  for package_row = eachrow(Jinnie.all(Package()))
    package = dfrow_to_m(package_row, Package())
    repo = Jinnie.from_package(package)
  end
end