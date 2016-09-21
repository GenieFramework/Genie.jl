module DashboardController
using App, Authentication, Authorization
@dependencies

function index(params)
  # with_authorization(:any, unauthorized_access, params) do
    ejl(:dashboard, :index, layout = :admin, params = params) |> respond
  # end
end

end