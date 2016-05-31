using GitHub
using Model
using DateParser

export Repo, Repos

type Repo <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  github::Nullable{GitHub.Repo}

  id::Nullable{Model.DbId}
  package_id::Nullable{Model.DbId}
  fullname::AbstractString
  readme::UTF8String
  participation::Array{Int}
  updated_at::Nullable{DateTime}

  belongs_to::Nullable{Dict{Symbol, Model.SQLRelation}}

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

        belongs_to = Dict(:belongs_to_package => Model.SQLRelation(:Package)), 
        
        on_dehydration = Repos.dehydrate, 
        on_hydration = Repos.hydrate
      ) = 
    new("repos", "id", github, id, package_id, fullname, readme, participation, updated_at, belongs_to, on_dehydration, on_hydration)
end

module Repos

using Genie
using Model
using Memoize
using DateParser
using GitHub
using JSON

function dehydrate(repo::Genie.Repo, field::Symbol, value::Any)
  return  if field == :participation 
            join(value, ",")
          elseif field == :updated_at
            value = Dates.now()
          else
            value
          end
end

function hydrate(repo::Genie.Repo, field::Symbol, value::Any)
  return  if field == :participation 
            map(x -> parse(x), split(value, ",")) 
          elseif field == :updated_at
            value = DateParser.parse(DateTime, value)
          else
            value
          end
end

@memoize function readme_from_github(repo::Genie.Repo; parse_markdown = false)
  readme =  try 
              Nullable(GitHub.readme(Base.get(repo.github), auth = Genie.GITHUB_AUTH))
            catch ex 
              Genie.log(ex, :debug)
              Nullable()
            end

  content = if isnull(readme)
              ""
            else 
              readme = Base.get(readme)

              try 
                mapreduce(x -> string(Char(x)), *, base64decode( Base.get(readme.content) ))
              catch ex
                Genie.log(ex, :debug)
                readall(download(string(Base.get(readme.download_url)))) 
              end
            end
  
  parse_markdown ? Markdown.parse(content) : content
end

function readme_from_github!(repo::Genie.Repo)
  repo.readme = readme_from_github(repo, parse_markdown = false)
end

function readme(repo::Genie.Repo; parse_markdown = true)
  parse_markdown ? Markdown.parse(repo.readme) : repo.readme
end

@memoize function participation_from_github(repo::Genie.Repo)
  stats = GitHub.stats(Base.get(repo.github), "participation", auth = Genie.GITHUB_AUTH)
  part_data = mapreduce(x -> string(Char(x)), *, stats.data) |> JSON.parse
  
  try   
    part_data["all"]
  catch ex
    Genie.log(ex)
    zeros(Int, 52) # 52 = nr of weeks in year
  end
end

function participation_from_github!(repo::Genie.Repo)
  repo.participation = participation_from_github(repo)
end

function from_package(package::Package)
  github_repo = GitHub.Repo(Genie.Packages.fullname(package))
  repo = Genie.Repo(github = github_repo, package_id = package.id, fullname = Genie.Packages.fullname(package))
  readme_from_github!(repo)
  participation_from_github!(repo)

  repo
end

function search(search_term::AbstractString; limit::SQLLimit = SQLLimit(), offset::Int = 0)
  sql = "
    SELECT 
      id, 
      ts_rank(repos_search.repo_info, query) rank, 
      ts_headline(readme, query) headline, 
      package_id
    FROM 
      (
      SELECT 
        id, 
        readme, 
        to_tsvector('english', readme) AS repo_info, 
        package_id
      FROM 
        repos
      ) repos_search, 
      to_tsquery($(Genie.Model.SQLInput(search_term))) query 
    WHERE 
      repos_search.repo_info @@ query
    ORDER BY 
      rank DESC
    LIMIT $(limit.value)
    OFFSET $offset
  "
  
  Model.query(sql)
end

function count_search_results(search_term::AbstractString)
  sql = "
    SELECT
      COUNT(*) AS results_count
    FROM
      (
      SELECT
        to_tsvector('english', readme) AS repo_info
      FROM
        repos
      ) repos_search,
      to_tsquery('$search_term') query
    WHERE
      repos_search.repo_info @@ query
  "
  Model.query(sql)[1, :results_count]
end

end