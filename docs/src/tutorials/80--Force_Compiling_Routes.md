# Force compiling Genie routes

Because Julia JIT-compiles the code, upon starting up the application, at the time of the first to a certain route, Julia will need to compile the function(s) which are responsible for handling the request. This means that the first request will potentially take many seconds to resolve, which might not be acceptable in a production environment. For such cases, once can use Genie itself to visit each defined route and trigger the compilation.

Here is a sample script which defines two `GET` routes and then automatically triggers them upon starting up the application:

```julia
using Genie, Genie.Router, Genie.Requests, Genie.Renderer.Json

route("/foo") do
  json(:foo => "Foo")
end

route("/bar") do
  json(:bar => "Bar")
end


function force_compile()
  sleep(5)

  for (name, r) in Router.named_routes()
    Genie.Requests.HTTP.request(r.method, "http://localhost:8000" * tolink(name))
  end
end

@async force_compile()

up(async = false)
```

In the snippet we define two routes. Then we add a function, `force_compile` which iterates over the routes and hits them through the web server. We then invoke the function, which will be executed with a 5 seconds delay, enough to allow the web server to start up.