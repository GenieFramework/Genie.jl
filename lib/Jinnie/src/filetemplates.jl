module FileTemplates

function new_database_migration(class_name)
  """
  using Jinnie
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

function new_task(class_name)
  """
  using Jinnie

  type $class_name
  end

  function description(_::$class_name)
    \"\"\"
    Description of the task here
    \"\"\"
  end

  function run_task!(_::$class_name, parsed_args = Dict())
    # Build something great
  end
  """
end

end