![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie
### The highly productive Julia web framework
Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.

### Current status
Genie is now compatible with Julia v1.0 (and it's the only version of Julia supported anymore).
This is a recent development (mid September 2018) so more testing is needed.

# Getting started

## Getting Genie
In a Julia session switch to `pkg>` mode to add `Genie`:
```julia
julia>] # switch to pkg> mode
pkg> add https://github.com/essenciary/Genie.jl
```

Alternatively, you can achieve the above using the `Pkg` API:
```julia
julia> using Pkg
julia> pkg"add https://github.com/essenciary/Genie.jl"
```

When finished, make sure that you're back to the Julian prompt (`julia>`)
and bring `Genie` into scope:
```julia
julia> using Genie
```

## Using Genie in an interactive environment (Jupyter/IJulia, REPL, etc)
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

Finally, now navigate to "http://localhost:8000" -- you should see the message "Hi there!".

We can define more complex URIs which can also map to previously defined functions:
```julia
julia> function hello_world()
         "Hello World!"
       end
julia> route("/hello/world", hello_world)
```
Obviously, the functions can be defined anywhere (in any other module) as long as they are accessible in the current scope.

You can now visit "http://localhost/hello/world" in the browser.

Of course we can access GET params:
```julia
julia> import Genie.Router: @params
julia> route("/echo/:message") do
         @params(:message)
       end
```

And we can even match by their types:
```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y)
       end
```
By default, GET params are parsed as `String` (more exactly, `SubString{String}`).
If type constraints are added, Genie will attempt to convert the `String` to the indicated type.

For the above to work, we also need to tell Genie how to perform the conversion:
```julia
julia> import Base.convert
julia> convert(::Type{Int}, s::SubString{String}) = parse(Int, s)
```

---

## Creating a Genie app (project)

Working with Genie in an interactive environment can be useful -- but usually we want to persist our application and reload it between sessions. One way to achieve that is to save it as an IJulia notebook and rerun the cells. However, you can get the most of Genie by working with Genie apps. A Genie app is an MVC web application which promotes the convention-over-configuration principle. Which means that by working with a few predefined files, within the Genie app structure, Genie can lift a lot of weight and massively improve development productivity. This includes automatic module loading and reloading, dedicated configuration files, logging, environments, code generators, and more.

In order to create a new app, run:
```julia
julia> Genie.REPL.new_app("your_cool_new_app")
```

Genie will
* create the app,
* install all the dependencies,
* automatically load the new app into the REPL,
* start an interactive `genie>` session,
* and start the web server on the default port (8000)

At this point you can confirm that everything worked as expected by visiting http://localhost:8000 in your favourite web browser. You should see Genie's welcome page.

Next, let's add a new route. This time we need to append it to the dedicated `routes.jl` file. Edit `/path/to/your_cool_new_app/config/routes.jl` in your favourite editor or run the next snippet (making sure you are in the app's directory):

```julia
julia> edit("config/routes.jl")
```

Append this at the bottom of the `routes.jl` file and save it:
```
route("/hello") do
  "Welcome to Genie!"
end
```

Visit `http://localhost:8000/hello` for a warm welcome!

### Loading an app

At any time, you can load an existing Genie app into the Julia REPL.
From the command line you can start a Genie interactive session by using

##### MacOS / Linux / *nix
```
$ bin/repl
```

If, instead, you want to directly start the server, use
```
$ bin/server
```

##### Windows
On Windows, `repl.bat` and `server.bat` are provided inside the `bin/` folder. Just double click them to start an interactive REPL session or a server session, respectively.

##### Juno / Jupyter / other Julia environment

```julia
using Genie
Genie.REPL.run_repl_app()
```

or simply

```julia
include("genie.jl")
```


## Next steps
If you want to learn more about Genie you can
* check out the API docs (out of date -- updates coming soon)
  * [Genie Web Framework](http://geniejl.readthedocs.io/en/latest/build/)
  * [SearchLight ORM](http://searchlightjl.readthedocs.io/en/latest/build/)
  * [Flax Templates](http://flaxjl.readthedocs.io/en/latest/build/)
* read the guides (coming soon)
* take a look at the slides for the Genie presentation at the 2017 JuliaCon [JuliaCon 2017 Genie Slides](https://github.com/essenciary/JuliaCon-2017-Slides/tree/master/v1.1)
* visit [genieframework.com](http://genieframework.com) for more resources


## Acknowledgements
* Genie uses a multitude of packages that have been kindly contributed by the Julia community.
* The awesome Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
