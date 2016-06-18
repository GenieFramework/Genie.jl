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

  html( :packages, :index, 
        packages = map(x -> Model.to_dict(x, expand_nullables = true, symbolize_keys = true), packages), 
        current_page = params[:page_number], page_size = params[:page_size], total_items = results_count) |> respond
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