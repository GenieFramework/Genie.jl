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
  Users.with_authorization(params) do
    "editing article"
  end
end

function dashboard(params)
  Users.with_authorization(params) do
    "dashboarding"
  end
end

end
end