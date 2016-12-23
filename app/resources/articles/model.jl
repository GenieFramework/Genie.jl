export Article, Articles
using Authentication

type Article <: AbstractModel
  _table_name::String
  _id::String

  validator::ModelValidator

  has_many::Vector{SearchLight.SQLRelation}

  id::Nullable{SearchLight.DbId}
  title::String
  summary::String
  content::String
  updated_at::DateTime
  published_at::Nullable{DateTime}
  slug::String

  before_save::Function

  scopes::Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}

  Article(;
    validator = ModelValidator([
      (:title,    Validation.not_empty),
      (:title,    Validation.min_length, (20)),
      (:content,  Validation.ArticlesValidator.not_empty_if_published),
      (:summary,  Validation.ArticlesValidator.not_empty_if_long_content, (2000))
    ]),

    has_many = [SQLRelation(ArticleCategory)],

    id = Nullable{SearchLight.DbId}(),
    title = "",
    summary = "",
    content = "",
    updated_at = Dates.now(),
    published_at = Nullable{DateTime}(),
    slug = "",

    before_save = Articles.before_save,

    scopes = Dict(:own            => [SQLWhere("user_id", 1)],
                  :top_thousand   => [SQLWhereExpression("articles.id BETWEEN ? AND ?", [1, 1_000])]
                  )

  ) = new("articles", "id", validator, has_many, id, title, summary, content, updated_at, published_at, slug, before_save, scopes)
end

module Articles
using App, Util, URIParser, Faker

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

function random()
  a = Article()
  a.title = (Faker.paragraph() ^ 2)
  (length(a.title) > 150) && (a.title = a.title[1:150])
  a.slug = replace(replace(a.title, " ", "-"), ".", "") |> lowercase
  a.content = Faker.paragraph() ^ 10
  a.summary = a.content[1:100]

  a
end

end
