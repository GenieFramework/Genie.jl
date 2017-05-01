"""
Functionality for authenticating Genie users. 
"""
module Authentication

using SearchLight, App, Genie, Sessions

export current_user, current_user!!

const USER_ID_KEY = :__auth_user_id


"""
    authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
    authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session

Stores the user id on the session.
"""
function authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
  Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session
  authenticate(user_id, params[:SESSION])
end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session

Removes the user id from the session.
"""
function deauthenticate(session) :: Sessions.Session
  Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
  deauthenticate(params[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session) :: Bool
  Sessions.is_set(session, USER_ID_KEY)
end
function is_authenticated(params::Dict{Symbol,Any}) :: Bool
  is_authenticated(params[:SESSION])
end


"""
    get_authentication(session) :: Nullable
    get_authentication(params::Dict{Symbol,Any}) :: Nullable

Returns the user id stored on the session, if available.
"""
function get_authentication(session) :: Nullable
  Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict{Symbol,Any}) :: Nullable
  get_authentication(params[:SESSION])
end


"""
    login(user, session) :: Nullable{Sessions.Session}
    login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}

Persists on session the id of the user object and returns the session.
"""
function login(user, session) :: Nullable{Sessions.Session}
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable{Sessions.Session}
end
function login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}
  login(user, params[:SESSION])
end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session) :: Sessions.Session
  deauthenticate(session)
end
function logout(params::Dict{Symbol,Any}) :: Sessions.Session
  logout(params[:SESSION])
end


"""
    current_user(session) :: Nullable{User}
    current_user(params::Dict{Symbol,Any}) :: Nullable{User}

Returns the `User` instance corresponding to the currently authenticated user, wrapped into a Nullable.
"""
function current_user(session) :: Nullable{User}
  auth_state = Authentication.get_authentication(session)
  if isnull(auth_state)
    Nullable{User}()
  else
    SearchLight.find_one(User, Base.get(auth_state))
  end
end
function current_user(params::Dict{Symbol,Any}) :: Nullable{User}
  current_user(params[:SESSION])
end


"""
    current_user!!(session) :: User
    current_user!!(params::Dict{Symbol,Any}) :: User

Attempts to get the `User` instance corresponding to the currently authenticated user - throws error on failure.
"""
function current_user!!(session) :: User
  try
    current_user(session) |> Base.get
  catch ex
    Logger.log("The current user is not authenticated", :err)
    rethrow(ex)
  end
end
function current_user!!(params::Dict{Symbol,Any}) :: User
  current_user!!(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session)
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict{Symbol,Any})
  without_authentication(f, params[:SESSION])
end

end
