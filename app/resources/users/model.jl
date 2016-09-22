export User

type User <: AbstractModel
  _table_name::String
  _id::String

  id::Nullable{Model.DbId}
  name::String
  email::String
  password::String
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
using App, Model, Authentication, Helpers, Sessions, DateParser
using SHA

function login(email::String, password::String, session::Sessions.Session)
  users = Model.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password) |> bytes2hex)]))

  if isempty(users)
    Logger.log("Failed login: Can't find user")
    return Nullable()
  end
  user = users[1]

  Authentication.login(user, session)
end

function logout(session::Sessions.Session)
  Authentication.logout(session)
end

function dehydrate(user::User, field::Symbol, value::Any)
  field == :updated_at ? Dates.now() : value
end

function hydrate!!(user::User, field::Symbol, value::Any)
  in(field, [:updated_at]) ? (user, DateParser.parse(DateTime, value)) : (user, value)
end

end
