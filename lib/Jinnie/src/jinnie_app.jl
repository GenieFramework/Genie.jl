type Jinnie_App
  config::Config
  server::Nullable{RemoteRef{Channel{Any}}}
  server_workers::Array{RemoteRef{Channel{Any}}, 1}

  Jinnie_App() = new(nothing, Nullable{RemoteRef{Channel{Any}}}(), Array{RemoteRef{Channel{Any}}, 1}())
  Jinnie_App(c) = new(c, Nullable{RemoteRef{Channel{Any}}}(), Array{RemoteRef{Channel{Any}}, 1}())
end