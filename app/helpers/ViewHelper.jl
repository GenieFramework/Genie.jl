module ViewHelper

export active_menu_class

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

end