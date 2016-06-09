using GitHub
using Genie
using Model

type ReposImportTask
end

function description(_::ReposImportTask)
  """
  Imports list of repos (name, URL) in database, using local package information and the GitHub pkg
  """
end

function run_task!(_::ReposImportTask, parsed_args = Dict())
  # for package in Genie.Model.find(Genie.Package)
  for i in (1:Model.count(Package))
    package = Model.find(Package, SQLQuery(limit = 1, offset = i-1, order = SQLOrder(:id, :asc))) |> first

    try 
      repo = Repos.from_package(package)
      Model.create_or_update_by!(repo, :package_id)
    catch ex 
      Genie.log(ex, :debug)
    end
  end
end