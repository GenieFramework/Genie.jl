module UserSessionsController
using Genie, Model, ControllerHelpers, Genie.Users, Authentication

function login(params)
  mustache(:user_sessions, :login, layout = :login, message = flash(params)) |> respond
end

function logout(params)
  Authentication.deauthenticate(session(params))
  flash("You've been successfully logged out", params)
  redirect_to("/login")
end

function create(params)
  if ! isnull(Users.login(params[:email], params[:password], session(params)))
    return redirect_to("/admin/dashboard")
  end

  flash("Unknown username and password combination", params)
  redirect_to("/login")
end

end