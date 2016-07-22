module UserSessionsController
using Genie, Model, ControllerHelpers

function login(params)
  html(:user_sessions, :login, layout = :login, message = flash(params)) |> respond
end

end
