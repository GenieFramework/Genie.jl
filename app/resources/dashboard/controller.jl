module DashboardController
using Genie, Model, Helpers, Genie.Users, Authentication, Authorization, ControllerHelper

function index(params)
  with_authorization(:any, unauthorized_access, params) do
    ejl(:dashboard, :index, layout = :admin) |> respond
  end
end

end