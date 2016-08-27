export Article

type Article <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  validator::ModelValidator

  id::Nullable{Model.DbId}
  title::AbstractString
  summary::AbstractString
  content::AbstractString
  updated_at::DateTime
  published_at::Nullable{DateTime}
  removed_at::Nullable{DateTime}

  Article(;
    validator = ModelValidator(
      [
        (:title,    Validation.not_empty),
        (:title,    Validation.min_length, (20)),
        (:content,  Validation.ArticlesValidator.not_empty_if_published),
        (:summary,  Validation.ArticlesValidator.not_empty_if_long_content, (2000))
      ]
    ),
    id = Nullable{Model.DbId}(),
    title = "",
    summary = "",
    content = "",
    updated_at = Dates.now(),
    published_at = Nullable{DateTime}(),
    removed_at = Nullable{DateTime}()
  ) = new("articles", "id", validator, id, title, summary, content, updated_at, published_at, removed_at)
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
