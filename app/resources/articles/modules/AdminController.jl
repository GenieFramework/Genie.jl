module AdminController
module Website
using Genie, Model, Authentication, ControllerHelpers, Genie.Users

function articles(params)
  Users.with_authorization(params) do
    ejl(:articles, :admin_list, layout = :admin, articles = Model.find(Article), params = params) |> respond
  end
end

function article_edit(params)
  Users.with_authorization(params) do
    ejl(:articles, :admin_item, layout = :admin, article = (Model.find_one(Article, params[:article_id]) |> _!!), params = params) |> respond
  end
end

function article_update(params)
  Users.with_authorization(params) do
    article::Article = Model.find_one(Article, params[:article_id]) |> _!!
    Model.update_with!!(article, params[:article])

    redirect_to("/admin/articles/$(article.id |> _!!)")
  end
end

end
end