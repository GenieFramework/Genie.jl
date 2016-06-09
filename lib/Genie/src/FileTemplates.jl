module FileTemplates

using Inflector

function new_database_migration(class_name::AbstractString)
  """
  using Genie
  using Database 

  type $class_name
  end 

  function up(_::$class_name)
    error("Not implemented")
  end

  function down(_::$class_name)
    error("Not implemented")
  end
  """
end

function new_task(class_name::AbstractString)
  """
  using Genie

  type $class_name
  end

  function description(_::$class_name)
    \"\"\"
    Description of the task here
    \"\"\"
  end

  function run_task!(_::$class_name, parsed_args = Dict{AbstractString, Any}())
    # Build something great
  end
  """
end

function new_model(model_name::AbstractString)
  pluralized_name = Inflector.to_plural(model_name) |> Base.get

  """
  export $model_name

  type $model_name <: Genie.AbstractModel
    _table_name::AbstractString
    _id::AbstractString

    id::Nullable{Model.DbId}

    $model_name(; 
      id = Nullable{Model.DbId}()
    ) = new("$(lowercase(pluralized_name))", "id", id) 
  end

  module $pluralized_name
  using Genie
  end
  """
end

function new_controller(controller_name::AbstractString)
  """
  module $(controller_name)Controller
  using Genie
  using SearchLight
  end
  """
end

function new_validator(validator_name::AbstractString)
  ""
end

function new_authorizer(authorizer_name::AbstractString)
  ""
end

end