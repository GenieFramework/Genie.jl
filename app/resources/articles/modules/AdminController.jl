module AdminController
module Website
using Genie, Model, Authentication, ControllerHelpers, Genie.Users

function articles(params)
  Users.with_authorization(params) do
    articles = Model.find(Article)
  end
end

function edit(params)
  Users.with_authorization(params) do
    "editing article"
  end
end

end
end