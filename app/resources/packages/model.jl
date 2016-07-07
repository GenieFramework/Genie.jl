export Package

type Package <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  url::AbstractString
  author_id::Nullable{Model.DbId}
  official::Bool

  has_one::Array{Model.SQLRelation,1}
  belongs_to::Array{Model.SQLRelation,1}

  repo::AbstractModel

  Package(; 
            id = Nullable{Model.DbId}(), 
            name = "", 
            url = "", 
            author_id = Nullable{Model.DbId}(), 
            official = false, 

            has_one = [Model.SQLRelation(Repo)], 
            belongs_to = [Model.SQLRelation(Author)], 

            repo = Repo()
          ) = new("packages", "id", id, name, url, author_id, official, has_one, belongs_to, repo) 
end
function Package(name::AbstractString, url::AbstractString) 
  p = Package()
  p.name = name
  p.url = url

  p
end

module Packages
using Genie

function fullname(p::Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")

  url_parts[length(url_parts) - 1] * "/" * package_name
end

function author(p::Package, a::Author)
  p.author_id = a.id
  p
end

function prepare_data(packages; details = false, search_results = Dict())
  packages_data = Array{Dict{Symbol,Any},1}()
  const package_item = Dict{Symbol,Any}()
  for pkg in packages
    package_item = Dict{Symbol,Any}()
    repo = Model.relationship_data!(pkg, Genie.Repo, :has_one)
    author = Model.relationship_data!(pkg, Genie.Author, :belongs_to)

    package_item[:id] = pkg.id |> Base.get
    package_item[:name] = pkg.name
    package_item[:url] = pkg.url
    package_item[:official] = pkg.official

    package_item[:repo_participation] = join(repo.participation, ",")
    package_item[:repo_description] = (repo.description |> ucfirst) * (endswith(repo.description, ".") ? "" : ".")
    package_item[:repo_subscribers_count] = repo.subscribers_count
    package_item[:repo_forks_count] = repo.forks_count
    package_item[:repo_stargazers_count] = repo.stargazers_count
    package_item[:repo_open_issues_count] = repo.open_issues_count
    package_item[:repo_html_url] = repo.html_url

    package_item[:author_name] = author.name
    package_item[:author_fullname] = author.fullname
    package_item[:author_company] = author.company
    package_item[:author_html_url] = author.html_url
    package_item[:author_followers_count] = author.followers_count

    if details 
      package_item[:repo_readme] = repo.readme |> Markdown.parse |> Markdown.html
    end

    if ! isempty(search_results)
      package_item[:search_rank] = search_results[package_item[:id]][:rank]
      package_item[:search_headline] = search_results[package_item[:id]][:headline] |> Markdown.parse |> Markdown.plain
    end

    push!(packages_data, package_item)
  end

  packages_data
end

end