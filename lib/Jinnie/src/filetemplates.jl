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

end