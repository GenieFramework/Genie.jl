export Author

type Author <: Genie.AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}

  Author(; 
    id = Nullable{Model.DbId}()
  ) = new("authors", "id", id) 
end

module Authors
using Genie
end
