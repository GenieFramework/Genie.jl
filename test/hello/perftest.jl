using Pkg
Pkg.activate(".")

using Genie
import Genie.Router: route

route("/hello") do
  "Welcome to Genie!"
end
Genie.AppServer.startup(; open_browser = false, async = false)
