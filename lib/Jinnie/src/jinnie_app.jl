type Jinnie_App
  config::Config
  server::Nullable{RemoteRef{Channel{Any}}}

  Jinnie_App() = new(nothing, Nullable{RemoteRef{Channel{Any}}}())
  Jinnie_App(c) = new(c, Nullable{RemoteRef{Channel{Any}}}())
end