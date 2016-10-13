export ArticleCategory, ArticleCategories

type ArticleCategory <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### validator
  validator::ModelValidator

  ### fields
  id::Nullable{SearchLight.DbId}
  article_id::Nullable{SearchLight.DbId}
  category_id::Nullable{SearchLight.DbId}

  ### relationships
  belongs_to::Vector{SearchLight.SQLRelation}

  ### constructor
  ArticleCategory(;
    validator = ModelValidator([]),

    id = Nullable{SearchLight.DbId}(),
    article_id = Nullable{SearchLight.DbId}(),
    category_id = Nullable{SearchLight.DbId}(),

    belongs_to = [SQLRelation(Article), SQLRelation(Category)]

  ) = new("article_categories", "id",
          validator,
          id, article_id, category_id,
          belongs_to
          )
end

module ArticleCategories
using App
end
