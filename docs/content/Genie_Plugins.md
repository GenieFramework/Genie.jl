# Genie Plugins

Genie plugins are special Julia packages which extend Genie apps with powerful  functionality by providing specific integration points. A Genie plugin is made of two parts:

1. the Julia package exposing the core functionality of the plugin, and
2. a files payload (controllers, modules, views, database migrations, initializers, etc) which are copied into the client app upon plugin installation.

## Using Genie Plugins

The plugins are created by third party Genie/Julia developers. Take this simple demo plugin as an example: https://github.com/GenieFramework/HelloPlugin.jl

In order to add the plugin to an existing Genie app you need to:

Add the HelloPlugin package to your Genie app, just like any other Julia Pkg dependency:
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

Make sure you run this in the Genie app REPL or that you are in a Julia session in the app's root dir. Otherwise pass the app's root dir as the argument for `install(dest::String)`.

### Running the Plugin

The installation will add a new `hello` resource in `app/resources/hello/` in the form of `HelloController.jl` and `views/greet.jl.html`. Also, in your Genie app's `plugins/` folder you fill find a new file, `helloplugin.jl` (which is the plugins' initializer and is automatically loaded by Genie early in the bootstrap process).

The `helloplugin.jl` initializer is defining a new route `route("/hello", HelloController.greet)`. If you restart your Genie app and navigate to `/hello` you will get the plugin's greeting.

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

---

## Demo

