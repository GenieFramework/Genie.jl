module API 
module V1

using Jinnie
using Model

function show(p::Jinnie.JinnieController, params::Dict{Symbol, Any}, req::Request, res::Response)
  package = Model.find_one(Jinnie.Package, params[:package_id]) |> Base.get
  Render.respond(Render.json(:packages, :show, package = package))
end

function search(p::Jinnie.JinnieController, params::Dict{Symbol, Any}, req::Request, res::Response)
  results_count = Repos.count_search_results(params[:q]) 
  search_results_df = Repos.search(params[:q], limit = SQLLimit(params[:page_size]), offset = (params[:page_number] - 1) * params[:page_size]) 

  search_results = Dict{Int, Any}([d[:package_id] => d for d in Model.dataframe_to_dict(search_results_df)])
  packages =  ! isempty(search_results) ? 
              Model.find(Package, SQLQuery(where = SQLWhere(:id, SQLInput(join( map(x -> string(x), search_results_df[:package_id]), ","), raw = true), "AND", "IN" ))) :
              []
  
  respond(Render.json(  :packages, :search, 
                        packages = packages, 
                        search_results = search_results, 
                        current_page = params[:page_number], 
                        page_size = params[:page_size], 
                        total_items = results_count))
end

end
end