using Genie
using Model

type ImportPackageAuthorsTask
end

function description(_::ImportPackageAuthorsTask)
  """
  Task to import the packages authors for existing / already imported packages
  """
end

function run_task!(_::ImportPackageAuthorsTask, parsed_args = Dict{AbstractString, Any}())
  for pkg in Model.all(Package)
    author_name = split(pkg.url, "/")[end-1]
    author = Model.find_one_by_or_create( Author(name = author_name), :name, author_name ) |> Base.get
    
    Packages.author(pkg, author) 
    Model.save!(pkg)
  end
end