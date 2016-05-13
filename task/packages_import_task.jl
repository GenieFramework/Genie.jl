using MetadataTools
using Genie
using Model

type PackagesImportTask
end

function description(_::PackagesImportTask)
  """
  Imports list of packages (name, URL) in database, using MetadataTools
  """
end

function run_task!(_::PackagesImportTask, parsed_args = Dict())
  for pkg in MetadataTools.get_all_pkg()
    package = Package(name = pkg[2].name, url = pkg[2].url)
    try 
      Model.create_or_update_by!(package, :url)
    catch ex
      Genie.log(ex, :debug)
    end
  end
end