### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 9b5db9f2-3974-11ec-28f2-65388bfe0fbf
md"""
# The secrets (`config/secrets.jl`) file

Confidential configuration data (like API keys, usernames, passwords, etc) should be added to the `config/secrets.jl` file. This file is by default added to `.gitignore` when creating a Genie app, so it won't be added to source control -- avoid that it is accidentally exposed.

## Scope

All the definitions (variables, constants, functions, modules, etc) added to the `secrets.jl` file are loaded into your app's module. So if your app is called `MyGenieApp`, the definitions will be available under the `MyGenieApp` module.

---
**HEADS UP**

Given the your app's name is variable, you can also access your app's module through the `UserApp` constant. So all the definitions added to `secrets.jl` can also be accessed through the `UserApp` module (`UserApp === MyGenieApp`).

---
"""

# ╔═╡ Cell order:
# ╟─9b5db9f2-3974-11ec-28f2-65388bfe0fbf
