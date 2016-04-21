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
  # for package in Jinnie.Model.find(Jinnie.Package)
  for i in (1:Model.count(Package))
    package = Model.find(Package, SQLQuery(limit = 1, offset = i-1, order = SQLOrder(:id, :asc))) |> first
    new_repo = Jinnie.Repos.from_package(package)
    existing_repo = Jinnie.Model.find_one_by(Jinnie.Repo, :package_id, Base.get(package.id))

    repo =  if ! isnull( existing_repo )
              Jinnie.log("REPO EXISTS", :debug)

              existing_repo = Base.get(existing_repo)

              existing_repo.fullname = new_repo.fullname
              existing_repo.readme = new_repo.readme
              existing_repo.participation = new_repo.participation

              existing_repo
            else 
              new_repo
            end
    try 
      Jinnie.Model.save!(repo)
    catch ex
      Jinnie.log(ex, :debug)
    end
  end
end