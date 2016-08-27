module AdminController
module Website
using Genie, Model, Authentication, Authorization, Helpers, Genie.Users, ControllerHelper, ViewHelper

function articles(params::Dict{Symbol,Any})
  with_authorization(:list, unauthorized_access, params) do
    ejl(:articles, :admin_list, layout = :admin, articles = Model.find(Article), params = params) |> respond
  end
end

function article_edit(params::Dict{Symbol,Any}; a::Article = Article())
  with_authorization(:edit, unauthorized_access, params) do
    article::Article = Model.is_persisted(a) ? a : (Model.find_one(Article, params[:article_id]) |> _!!)
    ejl(:articles, :admin_item, layout = :admin, article = article, params = params) |> respond
  end
end

function article_update(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    const article::Article = Model.find_one(Article, params[:article_id]) |> _!!
    params[:article][:updated_at] = Dates.now()
    article = Model.update_with!(article, params[:article])

    if Validation.validate!(article)
      Model.save!!(article)
      return redirect_to("/admin/articles/$(article.id |> _!!)")
    else
      flash("Article can't be saved - please check the errors", params)
      return article_edit(params, a = article)
    end
  end
end

end
end