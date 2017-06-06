![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie
### The highly productive Julia web framework

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.


## Quick start
In a Julia session clone `Genie` and its dependencies:
```julia
julia> Pkg.clone("https://github.com/essenciary/Genie.jl")
```

Bring it into scope:
```julia
julia> using Genie
```

Create a new app:
```julia
julia> Genie.REPL.new_app("your_cool_new_app")

info: Done! New app created at /path/to/your_cool_new_app
```

Genie will automatically load the new app into the REPL and start an interactive `genie>` session.

Edit `/path/to/your_cool_new_app/config/routes.jl` and append:

```julia
route("/hello") do
  "Hello - Welcome to Genie!"
end
```

Start the web server:
```julia
genie> AppServer.startup()
Listening on 0.0.0.0:8000...
```

Visit `http://localhost:8000/hello` for a warm welcome!

---

At any time, from the command line you can start a Genie interactive session by using
```
$> bin/repl
```

Or you can use
```
$> bin/server
```
to start the app in non-interactive mode.


## Next steps
If you want to learn more about Genie you can
* check out the API docs
  * [Genie Web Framework](http://geniejl.readthedocs.io/en/latest/build/)
  * [SearchLight ORM](http://searchlightjl.readthedocs.io/en/latest/build/)
  * [Flax Templates](http://flaxjl.readthedocs.io/en/latest/build/)
* dive into the demo apps
  * [TodoMVC](https://github.com/essenciary/genie-todo-mvc)
  * [PkgSearch web app and REST API](https://github.com/essenciary/pgksearch-api-website)
  * [Genie CMS]() (coming soon)
  * [Hashtag Analytics]() (coming soon)
* read the guides (coming soon)
* visit to [genieframework.com](http://genieframework.com) for more resources


## Acknowledgements
* Genie uses a multitude of packages that have been contributed by so many incredible developers.
* The amazing Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
* Built with the help and support of many amazing developers at the `julia-users` group.

Thank you all!
