![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie
### The highly productive Julia web framework
Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.

## Current status
Genie is now compatible with Julia v1.0 (and it's the only version of Julia supported anymore).
This is a recent development (mid September 2018) so more testing is needed.

## Adding Genie
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

---

## Creating a Genie app (project)

Create a new app:
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

Next, type:

```julia
julia> import Genie.Router: route
julia> route("/hello") do
        "Hello - Welcome to Genie!"
       end
```

Visit `http://localhost:8000/hello` for a warm welcome!

---

At any time, from the command line you can start a Genie interactive session by using

##### MacOS / Linux / *nix
```
$> bin/repl
```

Or you can use
```
$> bin/server
```
to start the app in non-interactive mode.

##### Windows
On Windows, `repl.bat` and `server.bat` are provided inside the `bin/` folder. Just double click them to start an interactive REPL session or a server session, respectively.

##### Juno / Jupyter / other Julia environment

```julia
using Genie

Genie.REPL.run_repl_app()
```


## Next steps
If you want to learn more about Genie you can
* check out the API docs
  * [Genie Web Framework](http://geniejl.readthedocs.io/en/latest/build/)
  * [SearchLight ORM](http://searchlightjl.readthedocs.io/en/latest/build/)
  * [Flax Templates](http://flaxjl.readthedocs.io/en/latest/build/)
* dive into the demo apps
  * [Hello World](https://github.com/essenciary/genie-demo-hello-world)
  * [Tweet Stats](https://github.com/essenciary/genie-demo-tweet-stats)
  * [TodoMVC](https://github.com/essenciary/genie-todo-mvc)
  * [PkgSearch web app and REST API](https://github.com/essenciary/pgksearch-api-website)
* read the guides (coming soon)
* take a look at the slides for the Genie presentation at the 2017 JuliaCon [JuliaCon 2017 Genie Slides](https://github.com/essenciary/JuliaCon-2017-Slides/tree/master/v1.1)
* visit [genieframework.com](http://genieframework.com) for more resources


## Acknowledgements
* Genie uses a multitude of packages that have been contributed by so many incredible developers.
* The amazing Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
* Built with the help and support of many amazing developers at the `julia-users` group.

Thank you all!
