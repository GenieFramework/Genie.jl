using Genie.Router

route("/") do params
  serve_static_file("welcome.html")
end