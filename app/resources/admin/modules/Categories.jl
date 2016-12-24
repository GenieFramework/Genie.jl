module Categories
using App, Authentication, Authorization, SearchLight
@dependencies

function categories(params::Dict{Symbol,Any})
  with_authorization(:list, unauthorized_access, params) do
    ejl(:admin, :categories, layout = :admin, categories = SearchLight.find(Category), params = params) |> respond
  end
end

function category_new(params::Dict{Symbol,Any}; c::Category = Category())
  with_authorization(:create, unauthorized_access, params) do
    ejl(:admin, :category, layout = :admin, category = c, params = params) |> respond
  end
end

function category_create(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    category = Category()
    SearchLight.update_with!(category, params[:category])

    if Validation.validate!(category)
      try
        category = SearchLight.save!!(category)
      catch ex
        Validation.push_error!(category, :unknown, :save_error, string(ex))
      end
    end

    if Validation.has_errors(category)
      flash("Category can't be saved - please check the errors", params)
      return category_new(params, c = category)
    end

    flash("Category created", params)
    to_link!!(:admin_categories_list) |> redirect_to
  end
end

function category_edit(params::Dict{Symbol,Any}; c::Category = Category())
  with_authorization(:edit, unauthorized_access, params) do
    category = SearchLight.is_persisted(c) ? c : SearchLight.find_one!!(Category, params[:category_id])
    ejl(:admin, :category, layout = :admin, category = category, params = params) |> respond
  end
end

function category_update(params::Dict{Symbol,Any})
  with_authorization(:edit, unauthorized_access, params) do
    category = SearchLight.find_one!!(Category, params[:category_id])
    SearchLight.update_with!(category, params[:category])

    if Validation.validate!(category)
      SearchLight.save!(category)
      return to_link!!(:admin_category_edit, category_id = Base.get(category.id)) |> redirect_to
    else
      flash("Category can't be saved - please check the errors", params)
      return category_edit(params, c = category)
    end
  end
end

end
