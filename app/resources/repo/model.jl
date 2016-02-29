using GitHub

type Repo <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString

  github::Nullable{GitHub.Repo}

  id::DbId
  package_id::DbId
  fullname::AbstractString
  readme::AbstractString
  participation::Array{Int}

  on_dehydration::Nullable{Function}
  on_hydration::Nullable{Function}

  Repo(; 
        github = Nullable{GitHub.Repo}(), 
        id = Nullable{Int}(), 
        package_id = Nullable{Int}(), 
        fullname = "", 
        readme = "", 
        participation = [], 
        on_dehydration = Jinnie.Repos.dehydrate, 
        on_hydration = Jinnie.Repos.hydrate
      ) = 
    new("repos", "id", github, id, package_id, fullname, readme, participation, on_dehydration, on_hydration)
end

module Repos

using Memoize
using GitHub
using JSON
using Jinnie

function dehydrate(repo::Jinnie.Repo, field::Symbol, value)
  return field == :participation ? join(value, ",") : value
end

function hydrate(repo::Jinnie.Repo, field::Symbol, value)
  return field == :participation ? map(x -> parse(x), split(value, ",")) : value
end

@memoize function readme_from_github(repo::Jinnie.Repo; parse_markdown = true)
  readme = GitHub.readme(Base.get(repo.github), auth = Jinnie.GITHUB_AUTH)
  content = try 
    mapreduce(x -> string(Char(x)), *, base64decode( Base.get(readme.content) ))
  catch 
    readall(download(string(Base.get(readme.download_url))))
  end

  return parse_markdown ? Markdown.parse(content) : content
end

function readme_from_github!(repo::Jinnie.Repo)
  repo.readme = readme_from_github(repo, parse_markdown = false)
end

function readme(repo::Jinnie.Repo; parse_markdown = true)
  return parse_markdown ? Markdown.parse(repo.readme) : repo.readme
end

@memoize function participation_from_github(repo::Jinnie.Repo)
  stats = GitHub.stats(Base.get(repo.github), "participation", auth = Jinnie.GITHUB_AUTH)
  part_data = mapreduce(x -> string(Char(x)), *, stats.data) |> JSON.parse
  return part_data["all"]
end

function participation_from_github!(repo::Jinnie.Repo)
  repo.participation = participation_from_github(repo)
end

function from_package(package::Jinnie.Package)
  github_repo = GitHub.Repo(Jinnie.Packages.fullname(package))
  repo = Jinnie.Repo(github = github_repo, package_id = package.id, fullname = Jinnie.Packages.fullname(package))
  readme_from_github!(repo)
  participation_from_github!(repo)
  return repo
end

end