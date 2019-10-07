# Loading and starting Genie apps

At any time, you can load and serve an existing Genie app. Loading a Genie app will bring into scope all your app's files, including the main app module, controllers, models, etcetera.

## Starting a Genie REPL session MacOS / Linux

The recommended approach is to start an interactive REPL in Genie's environment by executing `bin/repl` in the os shell, while in the project's root folder.

```sh
$ bin/repl
```

The app's environment will be loaded.

In order to start the web server, you can next execute:

```julia
julia> up()
```

If you want to directly start the server, use `bin/server` instead of `bin/repl`:

```sh
$ bin/server
```

This will automatically start the web server _in non interactive mode_.

Finally, there is the option to start the serve and drop to an interactive REPL, using `bin/serverinteractive` instead.

## Starting a Genie REPL on Windows

On Windows the workflow is similar to macOS and Linux, but dedicated Windows scripts, `repl.bat`, `server.bat`, and `serverinteractive.bat` are provided inside the project folder, within the `bin/` directory. Double click them or execute them in the os shell (cmd or PowerShell) to start an interactive REPL session or a server session, respectively, as explained in the previous paragraphs.

---
**HEADS UP**

It is possible that the Windows executables `repl.bat`, `server.bat`, and `serverinteractive.bat` are missing - this is usually the case if the app was generated on a Linux/Mac and ported to a windows computer. You can create them at anytime by running this generator in the Genie/Julia REPL (at the root of the Genie project):

```julia
julia> using Genie

julia> Genie.Generator.setup_windows_bin_files()
```

Alternatively, you can pass the path to the project as the argument to `setup_windows_bin_files`:

```julia
julia> Genie.Generator.setup_windows_bin_files("path/to/your/Genie/project")
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

## Manual loading in Julia's REPL

In order to load a Genie app within an open Julia REPL session, first make sure that you're in the root dir of a Genie app. This is the project's folder and you can tell by the fact that there should be a `bootstrap.jl` file, plus Julia's `Project.toml` and `Manifest.toml` files, amongst others. You can `julia> cd(...)` or `shell> cd ...` your way into the folder of the Genie app.

Next, from within the active Julia REPL session, we have to activate the local package environment:

```julia
julia> ] # enter pkg> mode

pkg> activate .
```

Then, back to the julian prompt, run the following to load the Genie app:

```julia
julia> using Genie

julia> Genie.loadapp()
```

The app's environment will now be loaded.

In order to start the web server execute

```julia
julia> startup()
```

---
**HEADS UP**

The recommended way to load an app is via the `bin/repl`, `bin/server` and `bin/serverinteractive` commands. It will correctly start the Julia process and start the app REPL with all the dependencies loaded with just one command.

---
