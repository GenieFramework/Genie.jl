module PackagesController
using Genie, Model

function index(params)
  results_count = SearchLight.count(Package)
  packages = SearchLight.find(Package, QQ(limit = params[:page_size], offset = (params[:page_number] - 1) * params[:page_size], order = QO(:id, :desc) ))

  results_count, packages
end

function search(params)
  results_count = Repos.count_search_results(params[:q]) 
  search_results_df = Repos.search(params[:q], limit = SQLLimit(params[:page_size]), offset = (params[:page_number] - 1) * params[:page_size]) 

  search_results = Dict{Int, Any}([d[:package_id] => d for d in Model.dataframe_to_dict(search_results_df)])
  packages =  ! isempty(search_results) ? 
              Model.find(Package, SQLQuery(where = SQLWhere(:id, SQLInput(join( map(x -> string(x), search_results_df[:package_id]), ","), raw = true), "AND", "IN" ))) :
              []

  if ! isempty(packages)
    sort!(packages, by = (p) -> search_results[p.id |> Util.expand_nullable][:rank], rev = true)
  end

  packages, search_results, results_count
end

# Website

module Website
using Genie
@in_repl using PackagesController

function index(params)
  results_count, packages = PackagesController.index(params)
  packages_data = Array{Dict{Symbol,Any},1}()
  
  const package_item = Dict{Symbol,Any}()
  for pkg in packages
    package_item = Dict{Symbol,Any}()
    repo = Model.relationship_data!(pkg, Genie.Repo, :has_one)

    package_item[:id] = pkg.id |> Base.get
    package_item[:name] = pkg.name
    package_item[:url] = pkg.url

    package_item[:repo_participation] = join(repo.participation, ",")
    package_item[:repo_description] = (repo.description |> ucfirst) * (endswith(repo.description, ".") ? "" : ".")
    package_item[:repo_subscribers_count] = repo.subscribers_count
    package_item[:repo_forks_count] = repo.forks_count
    package_item[:repo_stargazers_count] = repo.stargazers_count
    package_item[:repo_watchers_count] = repo.watchers_count
    package_item[:repo_open_issues_count] = repo.open_issues_count

    push!(packages_data, package_item)
  end

  html( :packages, :index, packages = packages_data) |> respond
end

end

# API

module API 
module V1
using Genie, Model
@in_repl using PackagesController

function index(params)
  results_count, packages = PackagesController.index(params)

  json( :packages, :index, 
        packages = packages, 
        current_page = params[:page_number], page_size = params[:page_size], total_items = results_count) |> respond
end

function show(params)
  package = SearchLight.find_one(Package, params[:package_id])
  if ! isnull(package) 
    package = Base.get(package)
    Render.respond(Render.json(:packages, :show, package = package))
  else 
    Render.respond(Render.JSONAPI.http_error(404))  
  end
end

function search(params)
  packages, search_results, results_count = PackagesController.search(params)
  
  Render.respond(Render.json(  :packages, :search, 
                                packages = packages, search_results = search_results, 
                                current_page = params[:page_number], page_size = params[:page_size], total_items = results_count) )
end

end
end

end