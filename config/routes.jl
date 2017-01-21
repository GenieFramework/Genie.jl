using Router

route(GET,  "/", "home#HomeController.index", named = :home, with = Dict(:message => "Welcome dear!"))
