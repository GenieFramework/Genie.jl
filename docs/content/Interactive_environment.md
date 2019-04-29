# Using Genie in an interactive environment (Jupyter/IJulia, REPL, etc)

Genie can be used for ad-hoc exploratory programming, to quickly whip up a web server
and expose your Julia functions.

Once you have `Genie` into scope, you can define a new `route`.
A `route` maps a URL to a function.

```julia
julia> import Genie.Router: route
julia> route("/") do
         "Hi there!"
       end
```

You can now start the web server using

```julia
julia> Genie.AppServer.startup()
```

Finally, now navigate to <http://localhost:8000> – you should see the message "Hi there!".

We can define more complex URIs which can also map to previously defined functions:

```julia
julia> function hello_world()
         "Hello World!"
       end
julia> route("/hello/world", hello_world)
```

Obviously, the functions can be defined anywhere (in any other module) as long as they are accessible in the current scope.

You can now visit <http://localhost:8000/hello/world> in the browser.

Of course we can access GET params:

```julia
julia> import Genie.Router: @params
julia> route("/echo/:message") do
         @params(:message)
       end
```

Accessing <http://localhost:8000/echo/ciao> should echo "ciao".

And we can even match by their types:

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y)
       end
```

By default, GET params are extracted as `SubString` (more exactly, `SubString{String}`).
If type constraints are added, Genie will attempt to convert the `SubString` to the indicated type.

For the above to work, we also need to tell Genie how to perform the conversion:

```julia
julia> import Base.convert
julia> convert(::Type{Int}, s::SubString{String}) = parse(Int, s)
```

Now if we access <http://localhost:8000/sum/2/3> we should see `5`

## Handling query string params

Query string params, which look like `...?foo=bar&baz=2` are automatically unpacked by Genie and placed into the `@params` collection. For example:

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y) + parse(Int, get(@params, :initial_value, "0"))
       end
```

Accessing <http://localhost:8000/sum/2/3?initial_value=10> will now output `15`.
