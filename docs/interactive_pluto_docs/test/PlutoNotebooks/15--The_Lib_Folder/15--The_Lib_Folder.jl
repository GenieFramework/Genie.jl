### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 02c81da6-3975-11ec-08d6-a35a7c2772d6
md"""
# The `lib/` folder

Genie makes it very easy to automatically load your existing Julia code (modules, files, etc) into the app, outside of the standard Genie MVC structure. You simply need to add your files and folders into the `lib/` folder.

---
**HEADS UP**

* If the `lib/` folder does not exist, just create it yourself: `julia> mkdir("lib")`
* Genie does not `include` the files placed within the `lib/` folder, but _recursively_ adds all the folders to the `LOAD_PATH` - so you can `include` the files yourself, as needed -- Genie/Julia will know were to find them in the LOAD_PATH.
* Files within `lib/` are not added to the `Revise` queue so they are not automatically reloaded by Genie if changed. If you make changes/add/remove files in `lib/` you need to restart the app or manually add them to be watched and reloaded by `Revise`. The reason being that the `lib/` folder is meant for legacy code. If you will actively develop the code, the recommended way is to use Genie's MVC structure, adding Models, Controllers, and Views as needed.

---"""

# ╔═╡ Cell order:
# ╟─02c81da6-3975-11ec-08d6-a35a7c2772d6
