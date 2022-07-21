# Loading and starting Genie apps

Genie apps are Julia projects that are composed of multiple modules distributed over multiple files.
Loading a Genie app will bring into scope all the app's files, including the main app module, controllers, models, etcetera.

## Starting a Genie REPL session MacOS / Linux

The quickest way to load an existing app in an interactive REPL is by executing `bin/repl` in the os shell,
while in the app's root folder.

```sh
$ bin/repl
```

The Genie app will be loaded.

In order to start the web server, you can next execute:

```julia
julia> up()
```

If you want to directly start the server without having access to the interactive REPL, use `bin/server` instead of `bin/repl`:

```sh
$ bin/server
```

This will automatically start the web server _in non interactive mode_.

## Starting a Genie REPL on Windows

On Windows the workflow is similar to macOS and Linux, but dedicated Windows scripts, `repl.bat`, `server.bat` are
provided inside the project folder, within the `bin/` directory. Double click them or execute them in the os shell
(cmd, Windows Terminal, PowerShell, etc) to start an interactive REPL session or a server session, respectively,
as explained in the previous paragraphs (the *nix and the Windows scripts run int the same way).

---
**HEADS UP**

It is possible that the scripts in the `bin/` folder are missing - this is usually the case if the
app was generated on an operating system (ex *nix) and ported to a different one (ex Windows).
You can create them at anytime by running the generator in the Genie/Julia REPL (at the root of the Genie project).

To generate the Windows scripts:

```julia
julia> using Genie

julia> Genie.Generator.setup_windows_bin_files()
```

And for the *nix scripts:

```julia
julia> Genie.Generator.setup_nix_bin_files()
```

Alternatively, we can pass the path where we want the files to be created as the argument to `setup_*_bin_files`:

```julia
julia> Genie.Generator.setup_windows_bin_files("path/to/your/Genie/project")
```

## REPL / Jupyter / Pluto / VSCode / other Julia environment

You might need to make the local package environment available, if it's not already activated:

```julia
using Pkg
Pkg.activate(".")
```

Then:

```julia
using Genie

Genie.loadapp()
```

This will assume that we're already in the app's root folder, and load the app (in other words that the `bootstrap.jl` file
is in the current working directory). Otherwise you can also pass the path to the Genie app's folder as the argument for
`loadapp`.

```julia
julia> Genie.loadapp("path/to/your/Genie/project")
```

## Manual loading in Julia's REPL

In order to load a Genie app within an open Julia REPL session, first make sure that you're in the root dir of a Genie app.
This is the project's folder and you can tell by the fact that there should be a `bootstrap.jl` file, plus Julia's
`Project.toml` and `Manifest.toml` files, amongst others. You can `julia> cd(...)` or `shell> cd ...` your way into the
folder of the Genie app.

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
julia> up()
```

