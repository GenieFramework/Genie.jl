module ViewHelper
using Genie, Validation, Helpers, App, URIParser

export active_menu_class, output_errors, output_flash, article_status_label, input_checked, pagination_navigation, article_uri

function current_menu(params)
  params[:action_controller] == "AdminController.Website.articles" && return :articles
  params[:action_controller] == "DashboardController.index" && return :dashboard
end

function is_active_menu(section::Symbol, params)
  section == current_menu(params)
end

function active_menu_class(section::Symbol, params, class_name = "active", alt_class_name = "")
  is_active_menu(section, params) ? class_name : alt_class_name
end

function output_errors(m, field::Symbol)
  Validation.has_errors_for(m, field) ? """<label class="control-label error genie-validation-error">$(Validation.errors_to_string(m, field, "<br/>\n", upper_case_first = true))</label>""" : ""
end

function output_flash(params::Dict{Symbol,Any})
  ! isempty( flash(params) ) ? """<div class="form-group alert alert-info">$(flash(params))</div>""" : ""
end

function article_status_label(status::Symbol)
  if status == :published
    "success"
  elseif status == :draft
    "info"
  else
    "danger"
  end
end

function input_checked(article)
  App.Articles.is_published(article) ? "checked" : ""
end

function pagination_navigation(params)
  number_of_pages(params) == 1 && return ""

  output = """<nav><ul class="pagination">"""
  for pg in 1:number_of_pages(params)
    output *= """<li><a href="$(paginated_uri(params, pg))">$pg</a></li>"""
  end
  output *= "</ul></nav>"
end

function article_uri(article)
  "/articles/" * URIParser.escape(article.title) * "-$(article.id |> Base.get)"
end

end
