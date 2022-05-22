### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 6abe6400-476f-11ec-0423-afbc13ad4a16
md"""
# Genie Plugins

Genie plugins are special Julia packages which extend Genie apps with powerful  functionality by providing specific integration points. A Genie plugin is made of two parts:

1. the Julia package exposing the core functionality of the plugin, and
2. a files payload (controllers, modules, views, database migrations, initializers, etc) which are copied into the client app upon plugin installation.

## Using Genie Plugins

The plugins are created by third party Genie/Julia developers. Take this simple demo plugin as an example: <https://github.com/GenieFramework/HelloPlugin.jl>

In order to add the plugin to an existing Genie app you need to:

Add the `HelloPlugin` package to your Genie app, just like any other Julia Pkg dependency:

"""

# ╔═╡ 9b87679e-66c0-4551-b166-44e56dd75745
md"""

```julia
julia> using Pkg

julia> Pkg.add(url="https://github.com/GenieFramework/HelloPlugin.jl")
```
"""

# ╔═╡ 2c393262-ee80-4a99-bf56-ac98b021be7f
md"""
Bring the package into scope:

"""

# ╔═╡ f8b6cd4b-891c-493b-8ef2-e9a108d20633
md"""

```julia
julia> using HelloPlugin
```
"""

# ╔═╡ 1abffbef-0109-417a-8788-0894fc64f40a
md"""
Install the plugin (this is a one time operation, when the package is added):

```julia

julia> HelloPlugin.install(@__DIR__)
```
"""

# ╔═╡ 257ae400-476b-4c3c-b3f9-766e583900ea
md"""
### Running the Plugin

The installation will add a new `hello` resource in `app/resources/hello/` in the form of `HelloController.jl` and `views/greet.jl.html`. Also, in your Genie app's `plugins/` folder you fill find a new file, `helloplugin.jl` (which is the plugins' initializer and is automatically loaded by Genie early in the bootstrap process).

The `helloplugin.jl` initializer is defining a new route `route("/hello", HelloController.greet)`. If you restart your Genie app and navigate to `/hello` you will get the plugin's greeting.

## Walkthrough

Create a new Genie app:
"""

# ╔═╡ 351a0df7-0566-4824-89d0-9ab3af54fc56
md"""

```julia

julia> using Genie

julia> Genie.newapp("Greetings", autostart = false)
```
"""

# ╔═╡ de53d6e1-f3eb-4b9c-8e4e-76a9fd7d5e4e
md"""

Add the plugin as a dependency:

```julia

julia> using Pkg

julia> Pkg.add(url="https://github.com/GenieFramework/HelloPlugin.jl")
```
"""

# ╔═╡ 8ad0a588-4569-4e1c-8bb3-46c8a19881a1
md"""
Bring the plugin into scope and run the installer (the installer should be run only once, upon adding the plugin package)

```julia
julia> using HelloPlugin
julia> HelloPlugin.install(@__DIR__)
```

The installation might show a series of logging messages informing about failure to copy some files or create folders. Normally it's nothing to worry about: these are due to the fact that some of the files and folders already exist in the app so they are not overwritten by the installer.

Restart the app to load the plugin:

```julia
julia> exit()
```

```bash
$ cd Greetings/
$ bin/repl
```

Start the server:

```julia
julia> Genie.startup()
```

Navigate to `http://localhost:8000/hello` to get the greeting from the plugin.

---

## Developing Genie Plugins

Genie provides an efficient scaffold for bootstraping a new plugin package. All you need to do is run this code to create your plugin project:

"""

# ╔═╡ 6678ed9c-3dc3-4615-8b8c-4da9a4c6aee2
md"""

```julia
julia> using genie
```
"""

# ╔═╡ d9a46470-9aac-48d5-9c2b-800b1b5b23b7
md"""

```julia
julia> Genie.Plugins.scaffold("GenieHelloPlugin") # use the actual name of your plugin
Generating project file
Generating project GenieHelloPlugin:
    GenieHelloPlugin/Project.toml
    GenieHelloPlugin/src/GenieHelloPlugin.jl
Scaffolding file structure

Adding dependencies
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating git-repo `https://github.com/genieframework/Genie.jl`
 Resolving package versions...
  Updating `~/GenieHelloPlugin/Project.toml`
  [c43c736e] + Genie v0.9.4 #master (https://github.com/genieframework/Genie.jl)
  Updating `~/GenieHelloPlugin/Manifest.toml`

Initialized empty Git repository in /Users/adrian/GenieHelloPlugin/.git/
[master (root-commit) 30533f9] initial commit
 11 files changed, 261 insertions(+)

Congratulations, your plugin is ready!
You can use this default installation function in your plugin's module:
  function install(dest::String; force = false)
    src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

    for f in readdir(src)
      isdir(f) || continue
      Genie.Plugins.install(joinpath(src, f), dest, force = force)
    end
  end
```

The scaffold command will create the file structure of your plugin, including the Julia project, the `.git` repo, and the file structure for integrating with Genie apps:

```
.
├── Manifest.toml
├── Project.toml
├── files
│   ├── app
│   │   ├── assets
│   │   │   ├── css
│   │   │   ├── fonts
│   │   │   └── js
│   │   ├── helpers
│   │   ├── layouts
│   │   └── resources
│   ├── db
│   │   ├── migrations
│   │   └── seeds
│   ├── lib
│   ├── plugins
│   │   └── geniehelloplugin.jl
│   └── task
└── src
    └── GenieHelloPlugin.jl
```

The core of the functionality shoud go into the `src/GenieHelloPlugin.jl` module. While everything placed within the `files/` folder should be copied into the corresponding folders of the Genie apps installing the plugin. You can add resources, controllers, models, database migrations, views, assets and any other files inside the `files/` folder to be copied.

The scaffolding will also create a `plugins/geniehelloplugin.jl` file - this is the initializer of the plugin and is meant to bootstrap the functionality of the plugin. Here you can load dependencies, define routes, set up configuration, etc.

Because any Genie plugin is a Julia `Pkg` project, you can add any other Julia packages as dependencies.

### The Installation Function

The main module file, present in `src/GenieHelloPlugin.jl` should also expose an `install(path::String)` function, responsible for copying the files of your plugin into the user Genie app. The `path` param is the root of the Genie app where the installation will be performed.

As copying the plugin's files is a standard but tedious operation, Genie provides some helpers to get you started. The `Genie.Plugins` module provides an `install(path::String, dest::String; force = false)` which can be used for copying the plugin's files to their destination in the app.

The scaffolding function will also recommend a default `install(path::String)` that you can use in your module:

```julia
function install(dest::String; force = false)
  src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isdir(f) || continue
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end
```

You can use it as a starting point - and add any other specific extra logic to it.

"""

# ╔═╡ Cell order:
# ╟─6abe6400-476f-11ec-0423-afbc13ad4a16
# ╟─9b87679e-66c0-4551-b166-44e56dd75745
# ╟─2c393262-ee80-4a99-bf56-ac98b021be7f
# ╟─f8b6cd4b-891c-493b-8ef2-e9a108d20633
# ╟─1abffbef-0109-417a-8788-0894fc64f40a
# ╟─257ae400-476b-4c3c-b3f9-766e583900ea
# ╟─351a0df7-0566-4824-89d0-9ab3af54fc56
# ╟─de53d6e1-f3eb-4b9c-8e4e-76a9fd7d5e4e
# ╟─8ad0a588-4569-4e1c-8bb3-46c8a19881a1
# ╟─6678ed9c-3dc3-4615-8b8c-4da9a4c6aee2
# ╟─d9a46470-9aac-48d5-9c2b-800b1b5b23b7
