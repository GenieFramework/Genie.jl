export Category, Categories

type Category <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### fields
  id::Nullable{SearchLight.DbId}
  name::String

  # validator
  validator::ModelValidator

  ### relations
  has_many::Vector{SearchLight.SQLRelation}

  ### constructor
  Category(;
    id = Nullable{SearchLight.DbId}(),
    name = "",

    validator = ModelValidator([
      (:name, Validation.CategoryValidator.not_empty)
    ]),

    has_many = [SQLRelation(ArticleCategory)]

  ) = new("categories", "id",
          id, name,
          validator,
          has_many
          )
end

module Categories
using App
end
