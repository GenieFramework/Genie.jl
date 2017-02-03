using Router

route("/", "home#HomeController.index", named = :home, with = Dict(:message => "Welcome deario!"))
route("about") do (params)
  "Hey man!"
end
