module AdminController
module Website
using Genie, Model, Authentication, ControllerHelpers, Genie.Users

function articles(params)
  Users.with_authorization(params) do
    mustache("admin listing articles", :admin) |> respond
  end
end

function edit(params)
  Users.with_authorization(params) do
    "editing article"
  end
end

end
end