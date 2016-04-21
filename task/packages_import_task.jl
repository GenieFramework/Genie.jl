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

@debug function run_task!(_::PackagesImportTask, parsed_args = Dict())
  for pkg in MetadataTools.get_all_pkg()
    existing_pkg = Model.find_one_by(Package, :name, pkg[2].name) 
    if ! isnull(existing_pkg) 
      existing_pkg = Base.get(existing_pkg)
      existing_pkg.url = pkg[2].url
      Model.save!(existing_pkg)
    else 
      Model.save!(Package(name = pkg[2].name, url = pkg[2].url))
    end
  end
end