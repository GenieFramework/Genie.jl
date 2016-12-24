module ArticlesController
module Website
using Genie, SearchLight, App, ViewHelper, Util, JSON
@dependencies

function index(params)
  articles = SearchLight.find(Article, SQLQuery(
                                        order = SQLOrder(:updated_at, :desc),
                                        limit = params[:page_size],
                                        offset = (params[:page_number] - 1) * params[:page_size],
                                        where = [SQLWhereExpression("published_at < NOW()"), SQLWhereExpression("published_at IS NOT NULL")],
                                        scopes = []))

  if Router.response_type(:json, params)
    return respond(articles |> JSON.json, params)
  end

  ejl(:articles,
      :index,
      layout = :posts,
      articles = articles,
      params = params) |> respond
end

function show(params)
  article = SearchLight.find_one_by(Article, :slug, params[:article_slug])

  isnull(article) && respond(404)
  ejl(:articles, :show, layout = :post, article = (article |> _!!), params = params) |> respond
end

end
end
