module UserSessionsController
using Genie, Model, ControllerHelpers, Genie.Users

function login(params)
  html(:user_sessions, :login, layout = :login, message = flash(params)) |> respond
end

function create(params)
  if ! isnull(Users.login(params[:email], params[:password], session(params)))
    return redirect_to("/admin/dashboard")
  end

  flash("Incorrect login - unknown username and password combination", params)
  redirect_to("/login")
end

end
