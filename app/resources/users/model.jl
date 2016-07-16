export User

type User <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}

  User(; 
    id = Nullable{Model.DbId}()
  ) = new("users", "id", id) 
end

module Users
using Genie
end
