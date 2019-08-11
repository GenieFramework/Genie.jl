# Hello world with Genie

Here are a few examples to quickly get you started with building Genie web apps.

## Running Genie interactively at the REPL or Jupyter

The simplest use case is to configure a routing function at the REPL and start the web server. That's all that's needed to publish your Julia code on the web:

```julia
julia> using Genie, Genie.Router

julia> route("/hello") do
          "Hello World"
       end

julia> startup()
```

The `route` function (available in the `Router` module) defines a mapping between a URL ("/hello") and a Julia function which will be invoked to send the response back to the client. In this case we're sending back the string "Hello World".

That's all we need - we have set up an app, a route, and started the web server. Open your favourite web browser and go to <http://127.0.0.1:8000/hello> - a friendly Genie awaits to greet you.

---
**HEADS UP**

Keep in mind that Julia JIT-compiles. The first time a function is invoked (our route handler), it gets compiled.
This will make the first response slower - but once the function is compiled, on all the subsequent requests, it will be super fast!

---

## Building a simple Hello World service

Genie can also be used in custom scripts, for example when building microservices with Julia. Here's how you can create a Hello World web service.

First, create a new file to host our code -- let's call it `geniews.jl`

```julia
julia> touch("geniews.jl")
```

Now, let's open it in the editor:

```julia
julia> edit("geniews.jl")
```

Here's the code:

```julia
using Genie, Genie.Router, Genie.Renderer

route("/hello.html") do
  html("Hello World")
end

route("/hello.json") do
  json("Hello World")
end

route("/hello.txt") do
   respond("Hello World", :text)
end

startup(8001, async = false)
```

We started by defining two routes -- but this time we used the `html` and `json` rendering functions (available in the `Renderer` module). These functions take their input and are responsible for outputting it in the correct format and document type (with the correct MIME), in our case HTML for `hello.html` and JSON for `hello.json`.

On the third `route`, we're serving text responses. Genie does not provide a specialized method for sending `text/plain` responses but we can use the generic `respond` function, indicating the desired MIME type. In our case `:text`, corresponding to `text/plain`. Other included MIME types are `:xml`, `:markdown`, and `:javascript`. If you're looking for something else, you can always pass the full mime type as a string, ie `"text/csv"`.

The `startup` function will launch the web server on port `8001`. This time, very important, we instructed it to start the server synchronously (that is _blocking_ the execution of the script), by passing the `async = false` argument. This way we make sure that our script stays running - otherwise, at the end of the script, it would normally exit, killing our server.

In order to launch the script, run `$ julia geniews.jl`.

## Batteries included

Although so far our apps have only simple logic, Genie readily makes available a rich set of features - you have already seen some bit of the rendering and the routing engines. For instance, logging (to file and console) can also be easily triggered with one line of code, caching with a couple more, and so on.

Another nice feature is that the app already handles "404 Page Not Found" and "500 Internal Error" reponses. If you try to access a URL which is not handled by the app, like say <http://127.0.0.1:8001/nothere> you'll see Genie's default 404 page. No worries, the default error pages can be overwritten with custom ones and we'll see how to do this later on.
