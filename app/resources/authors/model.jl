export Author

type Author <: Genie.AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString

  has_many::Nullable{Array{Model.SQLRelation, 1}}

  Author(; 
    id = Nullable{Model.DbId}(), 
    name = "", 
    has_many = [Model.SQLRelation(:Package)]
  ) = new("authors", "id", id, name, has_many) 
end

module Authors
using Genie
end
