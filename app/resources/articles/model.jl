export Article

type Article <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  title::AbstractString
  summary::AbstractString
  content::AbstractString
  updated_at::DateTime
  published_at::Nullable{DateTime}
  removed_at::Nullable{DateTime}

  Article(;
    id = Nullable{Model.DbId}(),
    title = "",
    summary = "",
    content = "",
    updated_at = Dates.now(),
    published_at = Nullable{DateTime}(),
    removed_at = Nullable{DateTime}()
  ) = new("articles", "id", id, title, summary, content, updated_at, published_at, removed_at)
end

module Articles
using Genie

function is_published(article::Article)
  ! is_removed(article) && ! isnull(article.published_at) && article.published_at |> _!! <= Dates.now()
end

function is_removed(article::Article)
  ! isnull(article.removed_at) && article.removed_at |> _!! <= Dates.now()
end

end
