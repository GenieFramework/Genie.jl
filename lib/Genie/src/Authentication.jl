module Authentication
using Genie, Sessions

export current_user, current_user!!

const USER_ID_KEY = :__auth_user_id

function authenticate(user_id::Any, session::Sessions.Session)
  Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::Any, params::Dict{Symbol,Any})
  authenticate(user_id, params[:SESSION])
end

function deauthenticate(session::Sessions.Session)
  Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict{Symbol,Any})
  deauthenticate(params[:SESSION])
end

function is_authenticated(session::Sessions.Session)
  Sessions.is_set(session, USER_ID_KEY)
end
function is_authenticated(params::Dict{Symbol,Any})
  is_authenticated(params[:SESSION])
end

function get_authentication(session::Sessions.Session)
  Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict{Symbol,Any})
  get_authentication(params[:SESSION])
end

function login(user, session::Sessions.Session)
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable
end
function login(user, params::Dict{Symbol,Any})
  login(user, params[:SESSION])
end

function logout(session::Sessions.Session)
  deauthenticate(session)
end
function logout(params::Dict{Symbol,Any})
  logout(params[:SESSION])
end

function current_user(session::Sessions.Session)
  auth_state = Authentication.get_authentication(session)
  if isnull(auth_state)
    Nullable()
  else
    Model.find_one_by(User, Symbol(User()._id), Base.get(auth_state))
  end
end
function current_user(params::Dict{Symbol,Any})
  current_user(params[:SESSION])
end

function current_user!!(session::Sessions.Session)
  try
    current_user(session) |> Base.get
  catch ex
    Genie.log("The current user is not authenticated", :err)
    rethrow(ex)
  end
end
function current_user!!(params::Dict{Symbol,Any})
  current_user!!(params[:SESSION])
end

function with_authentication(f::Function, fallback::Function, session::Sessions.Session)
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
  with_authentication(f, fallback, params[:SESSION])
end

function without_authentication(f::Function, session::Sessions.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict{Symbol,Any})
  without_authentication(f, params[:SESSION])
end

end