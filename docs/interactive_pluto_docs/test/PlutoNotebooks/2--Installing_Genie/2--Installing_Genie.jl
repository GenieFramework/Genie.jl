### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ bbdfb85a-309a-11ec-1e68-59d660aab7b3
md"""
# How to Install Genie

Genie development moves fast. Until reaching v1, the recommended installation is to get the latest and greatest Genie, by running off the `master` branch:


```julia
julia> ] # activate package mode
pkg(1.6)> add Genie#master
```

or 

```julia
pkg(1.6)> add https://github.com/GenieFramework/Genie.jl
```

Download stable tagged version of Genie 

```julia
julia> using Pkg
julia> Pkg.add("Genie")
```

or

```julia
julia> ] # enter package mode
pkg(1.6)> add Genie
```

"""



# ╔═╡ fce3a30a-813f-4875-ba3f-c98008019579
md"""
Genie, just like Julia, uses semantic versioning in the form vX.Y.Z to designate:

- X : major version, introducing breaking changes
- Y : minor version, brings new features, no breaking changes
- Z : patch version, fixes bugs, no new features or breaking changes

---
**HEADS UP**

Pre version 1, changes in Genie's minor version indicate breaking changes. So a new version 0.15 will introduce breaking changes from 0.14. Patch versions indicate non-breaking changes such as new features and patch releases.

---
"""

# ╔═╡ Cell order:
# ╟─bbdfb85a-309a-11ec-1e68-59d660aab7b3
# ╟─fce3a30a-813f-4875-ba3f-c98008019579
