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
using Genie, Model, Packages
@in_repl using PackagesController

function index(params)
  packages_count = SearchLight.count(Package)
  Genie.config.model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_EAGER

  top_packages = SearchLight.find(Package, QQ(where = QW("repos.stargazers_count", "NOT NULL", "IS"), limit = 20, order = QO("repos.stargazers_count", :desc)))
  new_packages = SearchLight.find(Package, QQ(where = QW("repos.github_created_at", "NOT NULL", "IS"), limit = 20, order = QO("repos.github_created_at", :desc)))
  updated_packages = SearchLight.find(Package, QQ(where = QW("repos.github_pushed_at", "NOT NULL", "IS"), limit = 20, order = QO("repos.github_pushed_at", :desc)))
  
  html( :packages, :index, 
        top_packages_data = Packages.prepare_data(top_packages), 
        new_packages_data = Packages.prepare_data(new_packages), 
        updated_packages_data = Packages.prepare_data(updated_packages), 
        packages_count = packages_count
      ) |> respond
end

function search(params)
  Genie.config.model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_EAGER
  params[:page_size] = 100
  packages, search_results, results_count = PackagesController.search(params)
  html(:packages, :search, search_term = params[:q], packages = Packages.prepare_data(packages; search_results = search_results)) |> respond
end

function show(params)
  Genie.config.model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_EAGER
  packages = SearchLight.find_by(Package, :id, params[:package_id])
  html(:packages, :show, packages = Packages.prepare_data(packages; details = true), package_name = packages[1].name) |> respond
end

end

# API

module API 
module V1
using Genie, Model
@in_repl using PackagesController

function index(params)
  results_count, packages = PackagesController.index(params)
  json( :packages, :index, packages = packages, current_page = params[:page_number], page_size = params[:page_size], total_items = results_count) |> respond
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