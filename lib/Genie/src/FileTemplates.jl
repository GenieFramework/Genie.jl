module FileTemplates

using Inflector

function new_database_migration(class_name::AbstractString)
  """
  using Genie, Database

  type $class_name
  end

  function up(::$class_name)
    # Database.query("")
    error("Not implemented")
  end

  function down(::$class_name)
    # Database.query("")
    error("Not implemented")
  end
  """
end

function new_task(class_name::AbstractString)
  """
  using Genie

  type $class_name
  end

  function description(::$class_name)
    \"\"\"
    Description of the task here
    \"\"\"
  end

  function run_task!(::$class_name, parsed_args = Dict{AbstractString, Any}())
    # Build something great
  end
  """
end

function new_model(model_name::AbstractString)
  pluralized_name = Inflector.to_plural(model_name) |> Base.get

  """
  export $model_name, $pluralized_name

  type $model_name <: AbstractModel
    _table_name::AbstractString
    _id::AbstractString

    id::Nullable{Model.DbId}

    $model_name(;
      id = Nullable{Model.DbId}()
    ) = new("$(lowercase(pluralized_name))", "id", id)
  end

  module $pluralized_name
  using App
  end
  """
end

function new_controller(controller_name::AbstractString)
  """
  module $(controller_name)Controller
  using Genie, Model, App
  end
  """
end

function new_validator(validator_name::AbstractString)
  """
  module $(validator_name)Validator
  using App, Model, Validation

  function not_empty{T<:AbstractModel}(::Symbol, m::T, args::Vararg{Any})::Bool
    isempty(m.some_property) && return false
    true
  end

  end
  """
end

function new_authorizer()
  """
  admin:
    create: all
    edit: all
    delete: all
    list: all
  editor:
    edit: all
    list: all
  writer:
    create: all
    edit: own
    delete: own
    list: own
  """
end

end