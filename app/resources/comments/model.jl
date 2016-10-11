export Comment, Comments

type Comment <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{SearchLight.DbId}

  Comment(;
    id = Nullable{SearchLight.DbId}()
  ) = new("comments", "id", id)
end

module Comments
using App
end
