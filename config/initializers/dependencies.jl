export @dependencies, @devtools

macro dependencies()
  :(using Genie, Model, Helpers, ControllerHelper, Renderer, Ejl, Cache, Router)
end

macro devtools()
  if ENV["GENIE_ENV"] == "dev"
    :(using Debug, StackTraces)
  end
end