export Article, Articles

type Article <: AbstractModel
  _table_name::String
  _id::String

  validator::ModelValidator

  id::Nullable{Model.DbId}
  title::String
  summary::String
  content::String
  updated_at::DateTime
  published_at::Nullable{DateTime}
  slug::String

  before_save::Function

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
    slug = "",

    before_save = Articles.before_save
  ) = new("articles", "id", validator, id, title, summary, content, updated_at, published_at, slug, before_save)
end

module Articles
using App, Util, URIParser

function is_published(article::Article)
  ! isnull(article.published_at) && article.published_at |> _!! <= Dates.now()
end

function is_draft(article::Article)
  ! is_published(article)
end

function status(article::Article)
  if is_published(article)
    :published
  else
    :draft
  end
end

function slugify(article::Article)
  replace(replace(article.title, r"[^a-zA-Z\d\s:]", ""), " ", "-") |> lowercase |> URIParser.escape
end

function before_save(article::Article)
  article.slug == "" && (article.slug = slugify(article))
  article
end

end
