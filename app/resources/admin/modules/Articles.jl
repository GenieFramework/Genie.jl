module Articles
using App, Authentication, Authorization, SearchLight
@dependencies

function articles(params::Dict{Symbol,Any})
  with_authorization(:list, unauthorized_access, params) do
    with_cache(cache_key(params[:action_controller], params[:page_number])) do
      params[:pagination_total] = SearchLight.count(Article)
      ejl(:admin, :articles, layout = :admin, articles = SearchLight.find(Article, SQLQuery(order = SQLOrder(:updated_at, :desc), limit = params[:page_size], offset = (params[:page_number] - 1) * params[:page_size])), params = params) |> respond
    end
  end
end

function article_new(params::Dict{Symbol,Any}; a::Article = Article())
  with_authorization(:create, unauthorized_access, params) do
    ejl(:admin, :article, layout = :admin, article = a, params = params) |> respond
  end
end

function article_create(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    article = Article()
    SearchLight.update_with!(article, params[:article])

    if Validation.validate!(article)
      try
        article = SearchLight.save!!(article)
      catch ex
        Validation.push_error!(article, :unknown, :save_error, string(ex))
      end
    end

    if Validation.has_errors(article)
      flash("Article can't be saved - please check the errors", params)
      return article_new(params, a = article)
    end

    flash("Article created", params)
    to_link!!(:admin_article_list) |> redirect_to
  end
end

function article_edit(params::Dict{Symbol,Any}; a::Article = Article())
  with_authorization(:edit, unauthorized_access, params) do
    article = SearchLight.is_persisted(a) ? a : SearchLight.find_one!!(Article, params[:article_id])
    ejl(:admin, :article, layout = :admin, article = article, params = params) |> respond
  end
end

function article_update(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    article = SearchLight.find_one!!(Article, params[:article_id])
    params[:article][:updated_at] = Dates.now()
    haskey(params[:article], :is_published) && App.Articles.is_draft(article) && (article.published_at = Nullable{DateTime}(Dates.now()))
    SearchLight.update_with!(article, params[:article])

    if Validation.validate!(article)
      SearchLight.save!(article)
      return to_link!!(:admin_article_edit, article_id = Base.get(article.id)) |> redirect_to
    else
      flash("Article can't be saved - please check the errors", params)
      return article_edit(params, a = article)
    end
  end
end

function article_publish(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    article = SearchLight.find_one!!(Article, params[:article_id])
    article.published_at = Dates.now()
    if Validation.validate!(article)
      SearchLight.save!!(article)
      return to_link!!(:admin_article_list) |> redirect_to
    else
      flash("Article can't be saved - please check the errors", params)
      return article_edit(params, a = article)
    end
  end
end

end