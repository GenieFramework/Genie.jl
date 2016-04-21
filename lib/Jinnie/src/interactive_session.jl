if current_module() == Main 
  using Jinnie
  using Model
  J = Jinnie

  # quick dev / repl helpers
  function r!() 
    workspace()
    reload("Jinnie")
  end
end