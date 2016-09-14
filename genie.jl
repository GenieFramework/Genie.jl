#!/usr/bin/env julia --color=yes
# addprocs(CPU_CORES - 1)
# addprocs(2)
dirname(@__FILE__) |> cd
include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))

isfile("env.jl") && include("env.jl")
if ! haskey(ENV, "GENIE_ENV")
  ENV["GENIE_ENV"] = "dev"
end
print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode\n\n")

# nworkers() < 4 && addprocs(4)
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")), abspath(pwd()))

import Genie
using Genie

try
  eval(Main, :(using Genie, Model))
catch ex
  Genie.log("Can't load modules Genie and Model into Main")
end