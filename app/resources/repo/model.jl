using Memoize
using GitHub
using JSON

type Repo <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString

  github::GitHub.Repo

  Repo(; github = nothing) = new("repos", "id", github)
end

@memoize function readme(repo::Jinnie.Repo; parse_markdown = true)
  readme = GitHub.readme(repo.github)
  content = mapreduce(x -> string(Char(x)), *, base64decode( Base.get(readme.content) ))
  return parse_markdown ? Markdown.parse(content) : content
end

@memoize function participation(repo::Jinnie.Repo)
  stats = GitHub.stats(repo.github, "participation")
  part_data = mapreduce(x -> string(Char(x)), *, stats.data) |> JSON.parse
  return part_data["all"]
end

function from_package(package::Jinnie.Package)
  github_repo = GitHub.Repo(fullname(package))
  return Jinnie.Repo(github = github_repo)
end