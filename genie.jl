#!/usr/bin/env julia --color=yes --depwarn=no --math-mode=fast
dirname(@__FILE__) |> cd
include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))

isfile("env.jl") && include("env.jl")
! haskey(ENV, "GENIE_ENV") && (ENV["GENIE_ENV"] = "dev")
in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = 4 : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = 1 )
print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n")

nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())

@everywhere push!(LOAD_PATH,  abspath(joinpath("lib", "Genie", "src")),
                              abspath(joinpath("lib", "SearchLight", "src")),
                              abspath(joinpath("lib", "Ejl", "src")),
                              abspath(pwd()))

@everywhere import Genie
using Genie