using Genie.Router

route("/") do
  Genie.Router.serve_static_file("/welcome.html")
end