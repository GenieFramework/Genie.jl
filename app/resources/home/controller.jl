module HomeController
using Genie, SearchLight, App, ViewHelper, Util
@dependencies

using JSON

function index(params)
  @show "I like big $(params[:like])"
  sleep(10)
  "I like big $(params[:like])"

  # content = ejl(:home, :index, layout = :home, params = params)[:html]
  # respond(content, params)
end

end
