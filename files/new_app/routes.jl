using Genie.Router

@get("/") do params
  serve_static_file("welcome.html")
end