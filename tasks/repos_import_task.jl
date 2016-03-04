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
  for package in Jinnie.Model.find(Jinnie.Package, Jinnie.Model.SQLQuery(where = [Jinnie.Model.SQLWhere(:id, 50, "AND", ">")], limit = Jinnie.Model.SQLLimit(50)))
    new_repo = Jinnie.Repos.from_package(package)
    existing_repo = Jinnie.Model.find_one_by(Jinnie.Repo, :package_id, Base.get(package.id))

    if ! isnull( existing_repo )
      println("REPO EXISTS")

      existing_repo = Base.get(existing_repo)

      existing_repo.fullname = new_repo.fullname
      existing_repo.readme = new_repo.readme
      existing_repo.participation = new_repo.participation

      Jinnie.Model.save!(existing_repo)
    else 
      Jinnie.Model.save!(new_repo)
    end
  end
end