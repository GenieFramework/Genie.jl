using MetadataTools
using Jinnie
using Database

type PackagesImportTask
end

function description(_::PackagesImportTask)
  """
  Imports list of packages (name, URL) in database, using MetadataTools
  """
end

function run_task!(_::PackagesImportTask, parsed_args = Dict())
  for pkg in MetadataTools.get_all_pkg()
    Jinnie.Model.save( Jinnie.Package( name = pkg[2].name, url = pkg[2].url ), upsert_strategy = :ignore )
  end
end