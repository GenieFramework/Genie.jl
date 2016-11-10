module ArticlesController
module Website
using Genie, SearchLight, App, ViewHelper, Util
@dependencies

function index(params)
  ejl(:articles,
      :index,
      layout = :posts,
      articles = SearchLight.find(Article, SQLQuery(
                                              order = SQLOrder(:updated_at, :desc),
                                              limit = params[:page_size],
                                              offset = (params[:page_number] - 1) * params[:page_size],
                                              where = [SQLWhere(:published_at, SQLInput("now()", raw = true), "<"), SQLWhere(:published_at, SQLInput("NULL", raw = true), "IS NOT")],
                                              scopes = [:top_two])),
      params = params) |> respond
end

function show(params)
  article = SearchLight.find_one_by(Article, :slug, params[:article_slug])

  isnull(article) && respond(404)
  ejl(:articles, :show, layout = :post, article = (article |> _!!), params = params) |> respond
end

end
end
