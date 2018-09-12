using Genie.Router
import Genie.Router: route, serve_static_file

route("/") do
  serve_static_file("/welcome.html")
end
