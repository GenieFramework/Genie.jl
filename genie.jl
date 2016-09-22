#!/usr/bin/env julia --color=yes
dirname(@__FILE__) |> cd
include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))

isfile("env.jl") && include("env.jl")
! haskey(ENV, "GENIE_ENV") && (ENV["GENIE_ENV"] = "dev")
in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = 4 : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = 1 )
print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n")

nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())
@everywhere push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")), abspath(pwd()))

@everywhere import Genie
using Genie

try
  eval(Main, :(using Genie, Model, App))
catch ex
  print_with_color(:red, "Can't load modules Genie and Model into Main")
end