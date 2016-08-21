export Article

type Article <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  title::UTF8String
  summary::UTF8String
  content::UTF8String
  updated_at::DateTime

  Article(;
    id = Nullable{Model.DbId}(),
    title = "",
    summary = "",
    content = "",
    updated_at = DateTime.now()
  ) = new("articles", "id", id, title, summary, content, updated_at)
end

module Articles
using Genie
end
