module HomeController
using Genie, SearchLight, App, ViewHelper, Util
@dependencies

using JSON

function index(params)
  # like = "I like big $(params[:like])"
  # content = ejl(:home, :likes, layout = :likes, like = like)[:html]
  # respond(content, params)

  respond(ejl(:home, :index, layout = :home, params = params)[:html], params)
end

end
