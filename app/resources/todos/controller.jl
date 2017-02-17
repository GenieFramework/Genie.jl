module TodosController

using App
@dependencies

function index(params)
  todos = SearchLight.find(Todo, SQLQuery(scopes = [:active]))
  if params[:response_type] == :json

  end
  html(:todos, :index, todos = todos) |> respond
end

function show(params)
  todo = SearchLight.find_one(Todo, params[:id])
  html(:todos, :show, check_nulls = [:todo => todo]) |> respond
end

function edit(params)
  todo = SearchLight.find_one(Todo, params[:id])
  html(:todos, :edit, check_nulls = [:todo => todo], params = params) |> respond
end

function update(params)
  try
    if haskey(params[:todo], :completed) && params[:todo][:completed] == "on"
      params[:todo][:completed] = true
    else
      params[:todo][:completed] = false
    end

    todo = SearchLight.find_one!!(Todo, params[:id])
    todo = SearchLight.update_with!!(todo, params[:todo])
    SearchLight.save!!(todo)

    redirect_to( link_to!!(:todo_item, id = params[:id]) )
  catch ex
    Logger.log(string(ex), :critical)
    error_500()
  end
end

end
