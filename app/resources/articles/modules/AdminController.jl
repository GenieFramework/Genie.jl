module AdminController
module Website

using Genie
using Model
using Authentication
using ControllerHelpers
using Genie.Users

function articles(params)
  Users.with_authorization(params) do
    "admin listing articles"
  end
end

function edit(params)
  "editing article"
end

end
end