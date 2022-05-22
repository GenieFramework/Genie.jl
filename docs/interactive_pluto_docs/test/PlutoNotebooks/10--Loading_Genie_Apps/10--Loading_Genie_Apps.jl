### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ cb961c7a-325f-11ec-17ae-d731e8fa429d
md"""

# Loading and starting Genie apps

At any time, you can load and serve an existing Genie app. Loading a Genie app will bring into scope all your app's files, including the main app module, controllers, models, etcetera.

## Starting a Genie REPL session MacOS / Linux

The recommended approach is to start an interactive REPL in Genie's environment by executing `bin/repl` in the os shell, while in the project's root folder.

"""

# ╔═╡ d6385f96-0d16-4dca-92f0-3041b6108de2
md"""
```sh
$ bin/repl
```

The app's environment will be loaded.

In order to start the web server, you can next execute:

```julia
julia> up()
```

"""

# ╔═╡ 05d1edf1-a48e-47f7-bf4f-b61ab86b0ae6
md"""
If you want to directly start the server, use `bin/server` instead of `bin/repl`:

```sh
$ bin/server
```
"""

# ╔═╡ 3117bf6b-8d66-464c-9769-3d8923e4c9e4
md"""
This will automatically start the web server _in non interactive mode_.

Finally, there is the option to start the serve and drop to an interactive REPL, using `bin/serverinteractive` instead.
"""

# ╔═╡ 5fa54447-ffd1-48e9-8526-67156920ea50
md"""
## Starting a Genie REPL on Windows

On Windows the workflow is similar to macOS and Linux, but dedicated Windows scripts, `repl.bat`, `server.bat`, and `serverinteractive.bat` are provided inside the project folder, within the `bin/` directory. Double click them or execute them in the os shell (cmd or PowerShell) to start an interactive REPL session or a server session, respectively, as explained in the previous paragraphs.

---
**HEADS UP**

It is possible that the Windows executables `repl.bat`, `server.bat`, and `serverinteractive.bat` are missing - this is usually the case if the app was generated on a Linux/Mac and ported to a windows computer. You can create them at anytime by running this generator in the Genie/Julia REPL (at the root of the Genie project):
"""

# ╔═╡ 407ad975-3018-49ac-98b0-9023c61f062b
md"""

```julia

julia> using Genie

julia> Genie.Generator.setup_windows_bin_files()
```
"""

# ╔═╡ 05072f0d-b81c-4892-bc9d-df0fcfac9489
md"""
Alternatively, you can pass the path to the project as the argument to `setup_windows_bin_files`:
"""

# ╔═╡ 70117605-5d7e-4530-bb71-1d9266801ba5
md"""
```julia
julia> Genie.Generator.setup_windows_bin_files("path/to/your/Genie/project")
```
"""

# ╔═╡ 81c7b086-2d3d-437f-89d8-cb91f38a94d3
md"""
## Juno / Jupyter / other Julia environment

For Juno, Jupyter, and other interactive environments, first make sure that you `cd` into your app's project folder.

We will need to make the local package environment available:
"""

# ╔═╡ d96f95b8-5cb9-40a6-a598-fa0b152afd67
md"""

```julia
using Pkg
Pkg.activate(".")
```
"""

# ╔═╡ 295e615a-8086-4441-b555-6824a7c4e78c
md"""
Then:

```julia
using Genie

Genie.loadapp()
```
"""

# ╔═╡ 5568bbb0-af35-45b8-b0e6-40df88b16484
md"""
## Manual loading in Julia's REPL

In order to load a Genie app within an open Julia REPL session, first make sure that you're in the root dir of a Genie app. This is the project's folder and you can tell by the fact that there should be a `bootstrap.jl` file, plus Julia's `Project.toml` and `Manifest.toml` files, amongst others. You can `julia> cd(...)` or `shell> cd ...` your way into the folder of the Genie app.

Next, from within the active Julia REPL session, we have to activate the local package environment:
"""

# ╔═╡ 74838525-f6e6-4c01-a1ce-51cf49cfe955
md"""

```julia
julia> ] # enter pkg> mode

pkg> activate .
```
"""

# ╔═╡ 64a032f4-7f43-4b98-89e7-5101fe0160c5
md"""
Then, back to the julian prompt, run the following to load the Genie app:

```julia
julia> using Genie

julia> Genie.loadapp()
```
"""

# ╔═╡ 5273d572-858c-48b4-9d23-d70e14e18ec6
md"""

The app's environment will now be loaded.

In order to start the web server execute

```julia
julia> startup()
```
"""

# ╔═╡ 16e41c1d-bad6-4292-b16a-cc1586c0ba99
md"""
---
**HEADS UP**

The recommended way to load an app is via the `bin/repl`, `bin/server` and `bin/serverinteractive` commands. It will correctly start the Julia process and start the app REPL with all the dependencies loaded with just one command.

---
"""

# ╔═╡ Cell order:
# ╟─cb961c7a-325f-11ec-17ae-d731e8fa429d
# ╟─d6385f96-0d16-4dca-92f0-3041b6108de2
# ╟─05d1edf1-a48e-47f7-bf4f-b61ab86b0ae6
# ╟─3117bf6b-8d66-464c-9769-3d8923e4c9e4
# ╟─5fa54447-ffd1-48e9-8526-67156920ea50
# ╟─407ad975-3018-49ac-98b0-9023c61f062b
# ╟─05072f0d-b81c-4892-bc9d-df0fcfac9489
# ╟─70117605-5d7e-4530-bb71-1d9266801ba5
# ╟─81c7b086-2d3d-437f-89d8-cb91f38a94d3
# ╟─d96f95b8-5cb9-40a6-a598-fa0b152afd67
# ╟─295e615a-8086-4441-b555-6824a7c4e78c
# ╟─5568bbb0-af35-45b8-b0e6-40df88b16484
# ╟─74838525-f6e6-4c01-a1ce-51cf49cfe955
# ╟─64a032f4-7f43-4b98-89e7-5101fe0160c5
# ╟─5273d572-858c-48b4-9d23-d70e14e18ec6
# ╟─16e41c1d-bad6-4292-b16a-cc1586c0ba99
