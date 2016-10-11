export Comment, Comments

type Comment <: AbstractModel
  _table_name::String
  _id::String

  id::Nullable{SearchLight.DbId}
  validator::ModelValidator

  belongs_to::Vector{SearchLight.SQLRelation}

  before_save::Function
  on_dehydration::Function
  on_hydration::Function

  Comment(;
    id = Nullable{SearchLight.DbId}(),

    validator = ModelValidator([
      (:title, Validation.CommentValidator.not_empty)
    ]),

    belongs_to = [],

    before_save = () -> warn("Not implemented"),
    on_dehydration = () -> warn("Not implemented"),
    on_hydration = () -> warn("Not implemented")
  ) = new("comments", "id", id, validator, belongs_to, before_save, on_dehydration, on_hydration)
end

module Comments
using App
end
