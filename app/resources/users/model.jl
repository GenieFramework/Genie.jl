export User, Users

type User <: AbstractModel
  _table_name::String
  _id::String

  id::Nullable{SearchLight.DbId}
  name::String
  email::String
  password::String
  hashed_password::String
  role_id::Nullable{SearchLight.DbId}
  updated_at::DateTime

  belongs_to::Vector{SearchLight.SQLRelation}

  on_dehydration::Function
  on_hydration!::Function
  after_hydration::Function

  role::Nullable{Symbol}

  User(;
    id = Nullable{SearchLight.DbId}(),
    name = "",
    email = "",
    password = "",
    hashed_password = "",
    role_id = Nullable{SearchLight.DbId}(),
    updated_at = DateTime(),

    belongs_to = [SearchLight.SQLRelation(Role, eagerness = RELATION_EAGERNESS_EAGER)],

    on_dehydration = Users.dehydrate,
    on_hydration! = Users.hydrate!,
    after_hydration = Users.after_hydration,

    role = Nullable{Symbol}()
  ) = new("users", "id", id, name, email, password, hashed_password, role_id, updated_at, belongs_to, on_dehydration, on_hydration!, after_hydration, role)
end

module Users

using App, SearchLight, Sessions, Authentication, Helpers, DateParser, SHA, Logger, Router, Match

function login(email::String, password::String, session)
  users = SearchLight.find(User, SQLQuery(where = [SQLWhere(:email, email), SQLWhere(:password, sha256(password) |> bytes2hex)]))

  if isempty(users)
    Logger.log("Failed login: Can't find user")
    return Nullable()
  end
  user = users[1]

  Authentication.login(user, session)
end

function logout(session)
  Authentication.logout(session)
end

function dehydrate(user::User, field::Symbol, value::Any)
  @match field begin
    :updated_at => Dates.now()
    :password   => value != user.hashed_password ? sha256(value) |> bytes2hex : value
    _           => value
  end
end

function hydrate!(user::User, field::Symbol, value::Any)
  in(field, [:updated_at]) ? (user, DateParser.parse(DateTime, value)) : (user, value)
end

function after_hydration(user::User)
  user.hashed_password = user.password
  user.role = SearchLight.relation_object!!(user, App.Role, SearchLight.RELATION_BELONGS_TO).name

  user
end

end
