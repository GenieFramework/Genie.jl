using Pkg
pkg"activate ."

using Revise
Revise.track(@__FILE__)

using Genie, Genie.Router, Genie.Renderer

route("/") do
  view = "<h1>Hello Genie!!</h1>"
  html(view)
end

route("/test") do
  "All good"
end

Genie.AppServer.startup(async = true)
