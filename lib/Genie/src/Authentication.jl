module Authentication
using Genie, Sessions

export current_user, current_user!!

const USER_ID_KEY = :__auth_user_id

function authenticate(user_id::Any, session::Sessions.Session)
  Sessions.set!(session, USER_ID_KEY, user_id)
end

function deauthenticate(session::Sessions.Session)
  Sessions.unset!(session, USER_ID_KEY)
end

function is_authenticated(session::Sessions.Session)
  Sessions.is_set(session, USER_ID_KEY)
end

function get_authentication(session::Sessions.Session)
  Sessions.get(session, USER_ID_KEY)
end

function login(user, session::Sessions.Session)
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable
end

function logout(session::Sessions.Session)
  deauthenticate(session)
end

function current_user(session::Sessions.Session)
  auth_state = Authentication.get_authentication(session)
  if isnull(auth_state)
    Nullable()
  else
    Model.find_one_by(User, Symbol(User()._id), Base.get(auth_state))
  end
end

function current_user!!(session::Sessions.Session)
  try
    current_user(session) |> Base.get
  catch ex
    Genie.log("The current user is not authenticated", :err)
    rethrow(ex)
  end
end

end