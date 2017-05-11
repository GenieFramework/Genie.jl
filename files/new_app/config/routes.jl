using Router

route("/") do
  Router.serve_static_file("/welcome.html")
end
