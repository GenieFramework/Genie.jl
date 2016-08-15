module DashboardController
using Genie, Model, ControllerHelpers, Genie.Users, Authentication

function index(params)
  Users.with_authorization(params) do
    ejl(:dashboard, :index, layout = :admin) |> respond
  end
end

end