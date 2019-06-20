# Genie Plugins

Genie plugins are special Julia packages which extend Genie apps with powerful  functionality by providing specific integration points. A Genie plugin is made of two parts:

1. the Julia package exposing the core functionality of the plugin, and
2. a files payload (controllers, modules, views, database migrations, initializers, etc) which are copied into the client app upon plugin installation.

## Using Genie Plugins

The plugins are created by third party Genie/Julia developers. Take this simple demo plugin as an example: <https://github.com/GenieFramework/HelloPlugin.jl>

In order to add the plugin to an existing Genie app you need to:

Add the `HelloPlugin` package to your Genie app, just like any other Julia Pkg dependency:
```julia
pkg> add https://github.com/GenieFramework/HelloPlugin.jl
```

Bring the package into scope:
```julia
julia> using HelloPlugin
```

Install the plugin (this is a one time operation, when the package is added):
```julia
julia> HelloPlugin.install(@__DIR__)
```

### Running the Plugin

The installation will add a new `hello` resource in `app/resources/hello/` in the form of `HelloController.jl` and `views/greet.jl.html`. Also, in your Genie app's `plugins/` folder you fill find a new file, `helloplugin.jl` (which is the plugins' initializer and is automatically loaded by Genie early in the bootstrap process).

The `helloplugin.jl` initializer is defining a new route `route("/hello", HelloController.greet)`. If you restart your Genie app and navigate to `/hello` you will get the plugin's greeting.

## Walkthrough

Create a new Genie app:

```julia
julia> using Genie

julia> Genie.newapp("Greetings", autostart = false)
```

Add the plugin as a dependency:

```julia
julia> ]

pkg> add https://github.com/GenieFramework/HelloPlugin.jl
```

Bring the plugin into scope and run the installer (the installer should be run only once, upon adding the plugin package)

```julia
julia> using HelloPlugin

julia> HelloPlugin.install(@__DIR__)
```

The installation might show a series of errors - these are due to the fact that some of the files and folders already exist so they are not overwritten by the installer.

Restart the app to load the plugin:

```julia
julia> exit()

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

```julia
julia> using Genie

julia> Genie.Plugins.scaffold("GenieHelloPlugin") # use the actual name of your plugin
```

The scaffold command will create the file structure of your plugin, including the Julia project, the `.git` repo, and the file structure for integrating with Genie apps.

The core of the functionality shoud go into the `src/GenieHelloPlugin.jl` module. While everything placed within the `files/` folder should be copied into the corresponding folders of the Genie apps installing the plugin. You can add resources, controllers, models, database migrations, views, assets and any other files inside the `files/` folder to be copied.

The scaffolding will also create a `plugins/geniehelloplugin.jl` file - this is the initializer of the plugin and is meant to bootstrap the functionality of the plugin. Here you can load dependencies, define routes, set up configuration, etc.

Because any Genie plugin is a Julia `Pkg` project, you can add any other Julia packages as dependencies.

### The Installation Function

The main module file, present in `src/GenieHelloPlugin.jl` should also expose an `install(path::String)` function, responsible for copying the files of your plugin into the user Genie app. The `path` param is the root of the Genie app where the installation must be performed.

As copying the plugin's files is a standard by tedious operation, Genie provides some helpers to get you started. The `Genie.Plugins` module provides an `install(path::String, dest::String; force = false)` which can be used for copying the plugin's files to their destination in the app.

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