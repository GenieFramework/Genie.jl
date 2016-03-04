if current_module() == Main 
Jinnie.log("Loading Jinnie app in REPL mode")
  
  # load modules
  using Jinnie
  J = Jinnie

  # quick dev / repl helpers
  function r!() 
    reload("Jinnie")
    reload("Model")
  end
end