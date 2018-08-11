export Role

mutable struct Role <: AbstractModel
  _table_name::String
  _id::String

  id::SearchLight.DbId
  name::Symbol

  has_one::Vector{SearchLight.SQLRelation}
  on_dehydration::Function

  Role(;
    id = SearchLight.DbId(),
    name = :user,
    has_one = [SearchLight.SQLRelation(User)],
    on_dehydration = Roles.dehydrate
  ) = new("roles", "id", id, name, has_one, on_dehydration)
end

module Roles

using App

function dehydrate(r::Role, field::Symbol, value::Any)
  return  if field == :name
            value = string(value)
          end
end

end
