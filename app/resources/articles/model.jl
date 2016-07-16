export Article

type Article <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}

  Article(; 
    id = Nullable{Model.DbId}()
  ) = new("articles", "id", id) 
end

module Articles
using Genie
end
