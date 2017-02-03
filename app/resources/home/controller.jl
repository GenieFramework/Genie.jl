module HomeController

using Genie, SearchLight, App
@dependencies

function index(params)
  flax(:home, :index, message = params[:message]) |> respond
end

end
