if current_module() == Main 
  # load modules
  using Jinnie
  using Model
  J = Jinnie

  # quick dev / repl helpers
  function r!() 
    reload("Database")
    reload("Model")
    reload("Migration")
    reload("FileTemplates")
    reload("Jinnie")
  end
end