export User

mutable struct User <: AbstractModel
  _table_name::String
  _id::String

  id::Nullable{SearchLight.DbId}
  name::String
  email::String
  password::String
  role_id::Nullable{SearchLight.DbId}

  belongs_to::Vector{SearchLight.SQLRelation}

  User(;
    id = Nullable{SearchLight.DbId}(),
    name = "",
    email = "",
    password = "",
    role_id = Nullable{SearchLight.DbId}(),
    updated_at = DateTime(),

    belongs_to = [SearchLight.SQLRelation(Role)]
  ) = new("users", "id", id, name, email, password, role_id, belongs_to)
end
