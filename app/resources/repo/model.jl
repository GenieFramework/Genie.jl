using GitHub

type Repo <: JinnieModel
  _table_name::AbstractString
  _id::AbstractString

  github::Nullable{GitHub.Repo}

  id::Nullable{Model.DbId}
  package_id::Nullable{Model.DbId}
  fullname::AbstractString
  readme::UTF8String
  participation::Array{Int}
  updated_at::Nullable{DateTime}

  belongs_to::Nullable{Array{Model.SQLRelation, 1}}

  on_dehydration::Nullable{Function}
  on_hydration::Nullable{Function}

  Repo(; 
        github = Nullable{GitHub.Repo}(), 
        id = Nullable{Model.DbId}(), 
        package_id = Nullable{Model.DbId}(), 
        fullname = "", 
        readme = "", 
        participation = [],
        updated_at = Nullable{DateTime}(),

        belongs_to = [Model.SQLRelation(:package, required = false)], 
        
        on_dehydration = Jinnie.Repos.dehydrate, 
        on_hydration = Jinnie.Repos.hydrate
      ) = 
    new("repos", "id", github, id, package_id, fullname, readme, participation, updated_at, belongs_to, on_dehydration, on_hydration)
end

module Repos

using GitHub
using JSON
using Jinnie

function dehydrate(repo::Jinnie.Repo, field::Symbol, value)
  return  if field == :participation 
            join(value, ",")
          elseif field == :updated_at
            value = Dates.now()
          else
            value
          end
end

function hydrate(repo::Jinnie.Repo, field::Symbol, value)
  return  if field == :participation 
            map(x -> parse(x), split(value, ",")) 
          elseif field == :updated_at
            value = DateParser.parse(DateTime, value)
          else
            value
          end
end

@memoize function readme_from_github(repo::Jinnie.Repo; parse_markdown = false)
  readme =  try 
              Nullable(GitHub.readme(Base.get(repo.github), auth = Jinnie.GITHUB_AUTH))
            catch ex 
              Jinnie.log(ex, :debug)
              Nullable()
            end

  content = if isnull(readme)
              ""
            else 
              readme = Base.get(readme)

              try 
                mapreduce(x -> string(Char(x)), *, base64decode( Base.get(readme.content) ))
              catch ex
                Jinnie.log(ex, :debug)
                readall(download(string(Base.get(readme.download_url)))) 
              end
            end
  
  parse_markdown ? Markdown.parse(content) : content
end

function readme_from_github!(repo::Jinnie.Repo)
  repo.readme = readme_from_github(repo, parse_markdown = false)
end

function readme(repo::Jinnie.Repo; parse_markdown = true)
  parse_markdown ? Markdown.parse(repo.readme) : repo.readme
end

@memoize function participation_from_github(repo::Jinnie.Repo)
  stats = GitHub.stats(Base.get(repo.github), "participation", auth = Jinnie.GITHUB_AUTH)
  part_data = mapreduce(x -> string(Char(x)), *, stats.data) |> JSON.parse
  
  try   
    part_data["all"]
  catch ex
    Jinnie.log(ex)
    zeros(Int, 52) # 52 = nr of weeks in year
  end
end

function participation_from_github!(repo::Jinnie.Repo)
  repo.participation = participation_from_github(repo)
end

function from_package(package::Jinnie.Package)
  github_repo = GitHub.Repo(Jinnie.Packages.fullname(package))
  repo = Jinnie.Repo(github = github_repo, package_id = package.id, fullname = Jinnie.Packages.fullname(package))
  readme_from_github!(repo)
  participation_from_github!(repo)

  repo
end

function search(search_term::AbstractString)
  sql = """
    SELECT 
      id, 
      fullname, 
      readme, 
      ts_rank(repos_search.repo_info, query) rank, 
      ts_headline(readme, query) 
    FROM 
      (
      SELECT 
        id, 
        fullname, 
        readme, 
        to_tsvector(fullname) || to_tsvector(readme) AS repo_info, 
        participation
      FROM repos
      LIMIT 10
      ) repos_search, 
      to_tsquery($(Jinnie.Model.SQLInput(search_term))) query 
    WHERE 
      repos_search.repo_info @@ query
    ORDER BY 
      rank DESC
  """
  result = Model.query(sql)
end

end