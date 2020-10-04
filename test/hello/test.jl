using Pkg
Pkg.activate(".")

using Genie, HTTP
import Genie.Router: route

route("/hello") do
  "Welcome to Genie!"
end
Genie.AppServer.startup(; open_browser = false)

HTTP.get("http://localhost:8000/hello")

exit(0)
