module HomeController
using Genie, Model, App, ViewHelper, Util
using Faker
@dependencies

function index(params)
  ejl(:home, :index, layout = :home, params = params) |> respond
end

end
