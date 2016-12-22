module HomeController
using Genie, SearchLight, App, ViewHelper, Util
@dependencies

function index(params)
  ejl(:home, :index, layout = :home, params = params) |> respond
end

end
