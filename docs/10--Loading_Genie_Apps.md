# Loading Genie apps

At any time, you can load and serve an existing Genie app. Loading a Genie app will bring into scope all your app's files, including the main app module, controllers, models, etcetera.

## Manual loading in Julia's REPL

First, make sure that you're in the root dir of a Genie app. This is the project's folder and you can tell by the fact that there should be a `bootstrap.jl` file, plus Julia's `Project.toml` and `Manifest.toml` files, amongst others.

Next, once you start a new Julia REPL session, we have to activate the local package environment:

```julia
julia> ] # enter pkg> mode

pkg> activate .
```

Then, back to the julian prompt, run

```julia
julia> using Genie

julia> Genie.loadapp()
```

The app's environment will now be loaded.

In order to start the web server execute

```julia
julia> startup()
```

## Starting a Genie REPL session MacOS / Linux

The recommended approach is to skip the manual loading and start an interactive REPL in Genie's environment by executing `bin/repl` in the os shell, again while in the project's root folder.

```shell
$ bin/repl
```

The app's environment will be loaded.

In order to start the web server execute:

```julia
julia> startup()
```

If you want to directly start the server, use `bin/server` instead of `bin/repl`:

```shell
$ bin/server
```

---
**HEADS UP**

The recommended way to load an app is via the `bin/repl` command. It will correctly start the Julia process and start the app REPL with all the dependencies loaded with just one command.

---

## Starting a Genie REPL on Windows

On Windows the workflow is similar to macOS and Linux, but dedicated Windows scripts, `repl.bat` and `server.bat` are provided inside the project folder, within the `bin/` folder. Double click them or execute them in the os shell to start an interactive REPL session or a server session, respectively, as explained in the previous paragraphs.

---
**HEADS UP**

It is possible that the Windows executables `repl.bat` and `server.bat` are missing - this is usually the case if the app was generated on a Linux/Mac. You can create them at anytime by running this in the Genie/Julia REPL (at the root of the Genie project):

```julia
julia> using Genie

julia> Genie.REPL.setup_windows_bin_files()
```

Alternatively, you can pass the path to the project as the argument to `setup_windows_bin_files`:

```julia
julia> Genie.REPL.setup_windows_bin_files("path/to/your/Genie/project")
```

## Juno / Jupyter / other Julia environment

For Juno, Jupyter, and other interactive environments, first make sure that you `cd` into your app's project folder.

We will need to make the local package environment available:

```julia
using Pkg
pkg"activate ."
```

Then:

```julia
using Genie

Genie.loadapp()
```
