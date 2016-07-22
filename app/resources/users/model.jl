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
  on_hydration::Nullable{Function}

  User(;
    id = Nullable{Model.DbId}(),
    name = "",
    email = "",
    password = "",
    admin = false,
    updated_at = DateTime(),

    on_dehydration = Users.dehydrate,
    on_hydration = Users.hydrate

  ) = new("users", "id", id, name, email, password, admin, updated_at, on_dehydration, on_hydration)
end

module Users
using Genie, Model
using SHA
using Auth
using Memoize

export current_user, current_user!!

const PASSWORD_CLOAK = "******"

function login(email::AbstractString, password::AbstractString, session::Sessions.Session)
  users = Model.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password))]))

  if isempty(users)
    Genie.log("Can't find user")
    return Nullable()
  end
  user = users[1]

  Auth.authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable
end

function logout(session::Sessions.Session)
  Auth.deauthenticate(session)
end

@memoize function current_user(session::Sessions.Session)
  auth_state = Auth.get_authentication(session)
  if isnull(auth_state)
    Nullable()
  else
    Model.find_one_by(User, Symbol(User()._id), auth_state |> Base.get)
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

function dehydrate(user::Genie.User, field::Symbol, value::Any)
  return  if field == :password
            value != PASSWORD_CLOAK ? sha256(value) : user._password_hash
          elseif field == :updated_at
            Dates.now()
          else
            value
          end
end

function hydrate(user::Genie.User, field::Symbol, value::Any)
  return  if in(field, [:updated_at])
            DateParser.parse(DateTime, value)
          elseif field == :password
            user._password_hash = value
            PASSWORD_CLOAK
          else
            value
          end
end

end
