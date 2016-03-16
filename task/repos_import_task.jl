using GitHub
using Jinnie
using Database

type ReposImportTask
end

function description(_::ReposImportTask)
  """
  Imports list of repos (name, URL) in database, using local package information and the GitHub pkg
  """
end

function run_task!(_::ReposImportTask, parsed_args = Dict())
  for package in Jinnie.Model.find(Jinnie.Package, Jinnie.Model.SQLQuery(where = [Jinnie.Model.SQLWhere(:id, 100, "AND", ">")], limit = Jinnie.Model.SQLLimit(5000)))
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