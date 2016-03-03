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
  for package in Jinnie.Model.all(Jinnie.Package)
    repo = Jinnie.Repos.from_package(package)
    @show repo
    Jinnie.Model.save(repo, upsert_strategy = :update)
  end
end