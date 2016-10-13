export Category, Categories

type Category <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### fields
  id::Nullable{SearchLight.DbId}
  name::String
  validator::ModelValidator

  ### relationships
  belongs_to::Vector{SearchLight.SQLRelation}
  has_one::Vector{SearchLight.SQLRelation}
  has_many::Vector{SearchLight.SQLRelation}

  ### constructor
  Category(;
    id = Nullable{SearchLight.DbId}(),
    name = "",

    validator = ModelValidator([
      (:name, Validation.CategoryValidator.not_empty)
    ]),

    belongs_to = [],
    has_one = [],
    has_many = []

  ) = new("categories", "id",
          id, name, validator,
          belongs_to, has_one, has_many
          )
end

module Categories
using App
end
