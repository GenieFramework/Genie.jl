type FileTemplate
end

function new_database_migration(_::FileTemplate, class_name)
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