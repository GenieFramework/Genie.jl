#!/usr/bin/env julia --color=yes
dirname(@__FILE__) |> cd

module App

push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")))

isfile("env.jl") && include("env.jl") 
if ! haskey(ENV, "GENIE_ENV") 
  ENV["GENIE_ENV"] = "dev"
end
include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))
print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode\n\n")

include(abspath(joinpath("config", "env", ENV["GENIE_ENV"] * ".jl")))

using Genie

end