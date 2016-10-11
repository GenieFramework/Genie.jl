module FileTemplates

using Inflector

function new_database_migration(class_name::AbstractString)
  """
  module $class_name
  using Genie, Database

  function up()
    # Database.query("")
    error("Not implemented")
  end

  function down()
    # Database.query("")
    error("Not implemented")
  end

  end
  """
end

function new_task(class_name::AbstractString)
  """
  module $class_name
  using Genie

  function description()
    \"\"\"
    Description of the task here
    \"\"\"
  end

  function run_task!()
    # Build something great
  end

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

    id::Nullable{SearchLight.DbId}

    $model_name(;
      id = Nullable{SearchLight.DbId}()
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
  using Genie, SearchLight, App
  end
  """
end

function new_validator(validator_name::AbstractString)
  """
  module $(validator_name)Validator
  using App, SearchLight, Validation

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