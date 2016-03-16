if current_module() == Main 
  # load modules
  using Jinnie
  J = Jinnie

  # quick dev / repl helpers
  function r!() 
    reload("Jinnie")
    reload("Database")
    reload("Model")
    reload("Migration")
    reload("FileTemplates")
  end
end