export Todo, Todos

type Todo <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  id::Nullable{SearchLight.DbId}
  title::String
  description::String
  created_at::DateTime
  updated_at::DateTime

  validator::ModelValidator

  on_dehydration::Function
  on_hydration::Function

  scopes::Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}

  ### constructor
  Todo(;
    id = Nullable{SearchLight.DbId}(),

    validator = ModelValidator([
      # (:title, Validation.TodoValidator.not_empty)
    ]),

    title = "",
    description = "",
    created_at = Dates.now(),
    updated_at = Dates.now(),

    on_dehydration = (m::Todo, field::Symbol, value::Any) -> begin
      if field == :updated_at
        Dates.now()
      end
    end,
    on_hydration = (m::Todo, field::Symbol, value::Any) -> begin
      if field == :updated_at

      end
    end,

    scopes = Dict(:active => [SQLWhereExpression("completed = FALSE")])

  ) = new("todos", "id",
          id,
          title,
          description,
          created_at,
          updated_at,

          validator,

          on_dehydration,
          on_hydration,

          scopes
          )
end

module Todos
using App, Faker

function random()
  todo = Todo()
  todo.title = Faker.sentence()
  todo.description = Faker.text()

  todo
end

end
