export Article

type Article <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  title::AbstractString
  summary::AbstractString
  content::AbstractString
  updated_at::DateTime

  Article(;
    id = Nullable{Model.DbId}(),
    title = "",
    summary = "",
    content = "",
    updated_at = Dates.now()
  ) = new("articles", "id", id, title, summary, content, updated_at)
end

module Articles
using Genie
end
