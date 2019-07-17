using Genie.Router

route("/") do
  serve_static_file("welcome.html")
end

route("/error500") do
  error_500("Something went wrong")
end

route("/error404") do
  error_404("the page you want")
end