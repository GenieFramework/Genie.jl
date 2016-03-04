if current_module() == Main 
  # load modules
  using Jinnie
  J = Jinnie

  # quick dev / repl helpers
  function r!() 
    reload("Jinnie")
    reload("Model")
  end
end