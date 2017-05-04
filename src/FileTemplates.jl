"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

using Inflector


"""
    new_database_migration(module_name::String) :: String

Default content for a new SearchLight migration.
"""
function new_database_migration(module_name::String) :: String
  """
  module $module_name

  using Genie, SearchLight

  function up()
    # SearchLight.query("")
    error("Not implemented")
  end

  function down()
    # SearchLight.query("")
    error("Not implemented")
  end

  end
  """
end


"""
    new_task(module_name::String) :: String

Default content for a new Genie task.
"""
function new_task(module_name::String) :: String
  """
  module $module_name

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


"""
    new_model(model_name::String, resource_name::String = model_name) :: String

Default content for a new SearchLight model.
"""
function new_model(model_name::String, resource_name::String = model_name) :: String
  pluralized_name = Inflector.to_plural(model_name) |> Base.get
  table_name = Inflector.to_plural(resource_name) |> Base.get |> lowercase

  """
  export $model_name, $pluralized_name

  type $model_name <: AbstractModel
    ### internals
    _table_name::String
    _id::String

    ### fields
    id::Nullable{SearchLight.DbId}

    ### validator
    validator::ModelValidator

    ### relations
    # belongs_to::Vector{SearchLight.SQLRelation}
    # has_one::Vector{SearchLight.SQLRelation}
    # has_many::Vector{SearchLight.SQLRelation}

    ### callbacks
    # before_save::Function
    # on_dehydration::Function
    # on_hydration::Function
    # on_hydration!::Function
    # after_hydration::Function

    ### scopes
    # scopes::Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}

    ### constructor
    $model_name(;
      id = Nullable{SearchLight.DbId}(),

      validator = ModelValidator([
        # (:title, Validation.$(model_name)Validator.not_empty)
      ]),

      # belongs_to = [],
      # has_one = [],
      # has_many = [],

      # before_save = (m::$model_name) -> warn("Not implemented"),
      # on_dehydration = (m::$model_name, field::Symbol, value::Any) -> warn("Not implemented"),
      # on_hydration = (m::$model_name, field::Symbol, value::Any) -> warn("Not implemented")

      # scopes = Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}()

    ) = new("$table_name", "id",
            id,
            validator
            # belongs_to, has_one, has_many,
            # before_save, on_dehydration, on_hydration
            # scopes
            )
  end

  module $pluralized_name
  using App
  end
  """
end


"""
    new_controller(controller_name::String) :: String

Default content for a new Genie controller.
"""
function new_controller(controller_name::String) :: String
  """
  module $(controller_name)Controller

  using App
  @dependencies

  end
  """
end


"""
    new_channel(channel_name::String) :: String

Default content for a new Genie channel.
"""
function new_channel(channel_name::String) :: String
  """
  module $(channel_name)Channel

  using Channels, App
  @dependencies

  end
  """
end


"""
    new_validator(validator_name::String) :: String

Default content for a new SearchLight validator.
"""
function new_validator(validator_name::String) :: String
  """
  module $(validator_name)Validator

  using App, SearchLight, Validation

  function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any})::Bool
    isempty(getfield(m, field)) && return false
    true
  end

  end
  """
end


"""
    new_authorizer() :: String

Default content for a new Genie ACL YAML file.
"""
function new_authorizer() :: String
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


"""
    new_test(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function new_test(plural_name::String, singular_name::String) :: String
  """
  using Genie, App, App.$(plural_name)

  ### Your tests here
  @test 1 == 1
  """
end

end
