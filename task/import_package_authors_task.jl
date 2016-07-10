using Genie
using Model
using GitHub

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
    author = Model.find_one_by_or_create( Author, :name, author_name ) |> Base.get

    try
      github_author = GitHub.owner(author_name, auth = GITHUB_AUTH)
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

    pkg = Genie.Packages.author(pkg, author)
    Model.save!!(pkg)
  end
end