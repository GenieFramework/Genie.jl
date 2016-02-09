type Jinnie_App
  config::Config
  server

  Jinnie_App() = new(nothing, nothing)
  Jinnie_App(c) = new(c, nothing)
end