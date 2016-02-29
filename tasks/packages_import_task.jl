using MetadataTools
using Jinnie
using Database

type Packages_Import_Task
end

function description(_::Packages_Import_Task)
  """
  Imports list of packages (name, URL) in database, using MetadataTools
  """
end

function run_task!(_::Packages_Import_Task, parsed_args = Dict())
  for pkg in MetadataTools.get_all_pkg()
    Jinnie.Model.save( Jinnie.Package( name = pkg[2].name, url = pkg[2].url ), upsert_strategy = :nothing )
  end
end