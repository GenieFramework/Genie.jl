export Comment, Comments

type Comment <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### fields
  id::Nullable{SearchLight.DbId}
  validator::ModelValidator

  ### relations
  belongs_to::Vector{SearchLight.SQLRelation}
  has_one::Vector{SearchLight.SQLRelation}
  has_many::Vector{SearchLight.SQLRelation}

  ### callbacks
  before_save::Function
  on_dehydration::Function
  on_hydration::Function

  ### constructor
  Comment(;
    id = Nullable{SearchLight.DbId}(),

    validator = ModelValidator([
      (:title, Validation.CommentValidator.not_empty)
    ]),

    belongs_to = [SQLRelation(Article), SQLRelation(User)],

    before_save = () -> warn("Not implemented"),
    on_dehydration = () -> warn("Not implemented"),
    on_hydration = () -> warn("Not implemented")
  ) = new("comments", "id",
          id, validator,
          belongs_to, has_one, has_many,
          before_save, on_dehydration, on_hydration
          )
end

module Comments
using App
end
