module TodosController

using App
@dependencies

function index(params)
  todos = SearchLight.find(Todo, SQLQuery(scopes = [:active]))
  # flax(:todos, :index; :todos => todos) |> respond
  html(:todos, :index; :todos => todos) |> respond
end

end
