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
    author = package_author(pkg)

    package = Package(name = pkg[2].name, url = pkg[2].url, official = true)
    package = Genie.Packages.author(package, author)
    try
      Model.create_or_update_by!!(package, :url)
    catch ex
      Genie.log(ex, :debug)
    end
  end
end

function package_author(pkg::Pair{UTF8String,MetadataTools.PkgMeta})
  author_name = split(pkg[2].url, "/")[end-1]
  author = Model.find_one_by_or_create(Author, :name, author_name) |> Base.get

  try
    github_author = GitHub.owner(author_name, auth = Genie.GITHUB_AUTH)
    author.fullname = isnull(github_author.name) ? "" : Base.get(github_author.name)
    author.company = isnull(github_author.company) ? "" : Base.get(github_author.company)
    author.location = isnull(github_author.location) ? "" : Base.get(github_author.location)
    author.html_url = github_author.html_url |> Base.get |> string
    author.blog_url = (isnull(github_author.blog) ? "" : Base.get(github_author.blog)) |> string
    author.followers_count = github_author.followers |> Base.get

    Model.save!!(author)
  catch ex
    Genie.log(ex, :err)
  end

  author
end