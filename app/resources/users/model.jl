export User

type User <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  email::AbstractString
  password::AbstractString
  admin::Bool
  updated_at::DateTime

  _password_hash::AbstractString

  on_dehydration::Nullable{Function}
  on_hydration!!::Nullable{Function}

  User(;
    id = Nullable{Model.DbId}(),
    name = "",
    email = "",
    password = "",
    admin = false,
    updated_at = DateTime(),

    _password_hash = "",

    on_dehydration = Users.dehydrate,
    on_hydration!! = Users.hydrate!!

  ) = new("users", "id", id, name, email, password, admin, updated_at, _password_hash, on_dehydration, on_hydration!!)
end

module Users
using Genie, Model, Authentication, ControllerHelpers
using SHA, Memoize

export current_user, current_user!!

const PASSWORD_CLOAK = "******"

function login(email::AbstractString, password::AbstractString, session::Sessions.Session)
  users = Model.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password) |> bytes2hex)]))

  if isempty(users)
    Genie.log("Can't find user")
    return Nullable()
  end
  user = users[1]

  Authentication.authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable
end

function logout(session::Sessions.Session)
  Authentication.deauthenticate(session)
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

function is_authorized(params::Dict{Symbol,Any})
  Authentication.is_authenticated(session(params)) && expand_nullable(current_user(session(params)), default = User()).admin
end

function with_authorization(f::Function, params::Dict{Symbol,Any})
  if ! is_authorized(params)
    flash("Unauthorized access", params)
    return redirect_to("/login")
  else
    f()
  end
end

function dehydrate(user::Genie.User, field::Symbol, value::Any)
  return  if field == :password
            value != PASSWORD_CLOAK ? bytes2hex(sha256(value)) : user._password_hash
          elseif field == :updated_at
            Dates.now()
          else
            value
          end
end

function hydrate!!(user::Genie.User, field::Symbol, value::Any)
  return  if in(field, [:updated_at])
            user, DateParser.parse(DateTime, value)
          elseif field == :password
            user._password_hash = value
            user, PASSWORD_CLOAK
          else
            user, value
          end
end

end
