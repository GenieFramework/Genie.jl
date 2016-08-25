export User

type User <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  email::AbstractString
  password::AbstractString
  role_id::Nullable{Model.DbId}
  updated_at::DateTime

  belongs_to::Vector{Model.SQLRelation}

  on_dehydration::Function
  on_hydration!!::Function

  User(;
    id = Nullable{Model.DbId}(),
    name = "",
    email = "",
    password = "",
    role_id = Nullable{Model.DbId}(),
    updated_at = DateTime(),

    belongs_to = [Model.SQLRelation(Role)],

    on_dehydration = Users.dehydrate,
    on_hydration!! = Users.hydrate!!
  ) = new("users", "id", id, name, email, password, role_id, updated_at, belongs_to, on_dehydration, on_hydration!!)
end

module Users
using Genie, Model, Authentication, Helpers
using SHA, Memoize

function login(email::AbstractString, password::AbstractString, session::Sessions.Session)
  users = Model.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password) |> bytes2hex)]))

  if isempty(users)
    Genie.log("Failed login: Can't find user")
    return Nullable()
  end
  user = users[1]

  Authentication.login(user, session)
end

function logout(session::Sessions.Session)
  Authentication.logout(session)
end

function dehydrate(user::Genie.User, field::Symbol, value::Any)
  return  if field == :updated_at
            Dates.now()
          else
            value
          end
end

function hydrate!!(user::Genie.User, field::Symbol, value::Any)
  return  if in(field, [:updated_at])
            user, DateParser.parse(DateTime, value)
          else
            user, value
          end
end

end
