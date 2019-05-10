![Genie Logo](docs/content/img/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie

## The highly productive Julia web framework

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.

### Current status

Genie is compatible with Julia v1.0 and up.

---

# Getting started

## Installing Genie

In a Julia session switch to `pkg>` mode to add `Genie`:

```julia
julia>] # switch to pkg> mode
pkg> add https://github.com/genieframework/Genie.jl
```

Alternatively, you can achieve the above using the `Pkg` API:

```julia
julia> using Pkg
julia> pkg"add https://github.com/genieframework/Genie.jl"
```

When finished, make sure that you're back to the Julian prompt (`julia>`)
and bring `Genie` into scope:

```julia
julia> using Genie
```
---

## Using Genie

Genie can be used for all scenarions from simple ad-hoc programming to a fullstack web framework. Below are some use cases each time explained with a simple example.

[Using Genie in an interactive environment (Jupyter/IJulia, REPL, etc)](docs/content/Interactive_environment.md)

[Developing a simple API backend](docs/content/Simple_API_backend.md)

[Working with Genie apps (projects)](docs/content/Working_with_Genie_apps/index.md)

## Coming soon

In addition to use cases above, will be coming soon in guides:

- Adding data integrity rules with ModelValidators
- Caching our responses
- Using WebSockets and WebChannels
- Setting up an admin area
- Configuring Genie apps
- Publishing Genie apps in production
- The Genie Docker image
- Genie Plugins
- Genie Authentication Plugin

---

## Acknowledgements

* Genie uses a multitude of packages that have been kindly contributed by the Julia community.
* The awesome Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
