module Authentication

using Sessions

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

end