module ViewHelper
using Genie, Validation

export active_menu_class, output_errors, output_flash

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
  Validation.has_errors_for(m, field) ? """<label class="control-label error">$(Validation.errors_to_string(m, field))</label>""" : ""
end

function output_flash(params)
  ! isempty( flash(params) ) ? """<div class="form-group alert alert-info">$(flash(params))</div>""" : ""
end

end