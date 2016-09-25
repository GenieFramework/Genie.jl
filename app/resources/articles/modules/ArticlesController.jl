module ArticlesController
module Website
using Genie, Model, App, ViewHelper, Util
@dependencies

function index(params)
  ejl(:articles,
      :index,
      layout = :blog,
      articles = Model.find(Article, SQLQuery(order = SQLOrder(:updated_at, :desc),
                                              limit = params[:page_size],
                                              offset = (params[:page_number] - 1) * params[:page_size],
                                              where = [SQLWhere(:published_at, SQLInput("now()", raw = true), "<"), SQLWhere(:published_at, SQLInput("NULL", raw = true), "IS NOT")])),
      params = params) |> respond
end

function show(params)
  "Hello"
end

end
end
