module API 
module V1

using Genie
using Model

function show(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)
  package = SearchLight.find_one(Package, params[:package_id])
  if ! isnull(package) 
    package = Base.get(package)
    Render.respond(Render.json(:packages, :show, package = package))
  else 
    Render.respond(Render.JSONAPI.error(404))  
  end
end

function search(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)
  results_count = Repos.count_search_results(params[:q]) 
  search_results_df = Repos.search(params[:q], limit = SQLLimit(params[:page_size]), offset = (params[:page_number] - 1) * params[:page_size]) 

  search_results = Dict{Int, Any}([d[:package_id] => d for d in Model.dataframe_to_dict(search_results_df)])
  packages =  ! isempty(search_results) ? 
              Model.find(Package, SQLQuery(where = SQLWhere(:id, SQLInput(join( map(x -> string(x), search_results_df[:package_id]), ","), raw = true), "AND", "IN" ))) :
              []

  if ! isempty(packages)
    sort!(packages, by = (p) -> search_results[p.id |> Util.expand_nullable][:rank], rev = true)
  end
  
  Render.respond(Render.json(  :packages, :search, 
                                packages = packages, 
                                search_results = search_results, 
                                current_page = params[:page_number], 
                                page_size = params[:page_size], 
                                total_items = results_count))
end

end
end