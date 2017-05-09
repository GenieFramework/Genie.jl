module UserSessionsController

using Genie, SearchLight, App, Authentication
@dependencies

function show_login()
  Flax.include_template("/Users/adrian/Dropbox/Projects/todo_mvc/app/layouts/login.flax.html", partial = false)
end

function login()
  success = do_login(@params(:email), @params(password), session(@params()))
  if isnull(success)
    flash("Unknown username and password combination", @params())
    redirect_to("/login")
  else
    flash("You are logged in", @params())
    redirect_to("/")
  end
end

function do_login(email::String, password::String, session::Sessions.Session) :: Nullable
  users = SearchLight.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password) |> bytes2hex)]))

  if isempty(users)
    Logger.log("Failed login: Can't find user")
    return Nullable()
  end
  user = users[1]

  Authentication.login(user, session)
end

function logout(session::Sessions.Session)
  Authentication.logout(session(@params()))
end

end
