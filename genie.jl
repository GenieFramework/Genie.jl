#!/usr/bin/env julia --color=yes
# addprocs(CPU_CORES - 1)
# addprocs(2)
dirname(@__FILE__) |> cd
include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))

@everywhere function go_genie()
  push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")), abspath(pwd()))

  isfile("env.jl") && include("env.jl")
  if ! haskey(ENV, "GENIE_ENV")
    ENV["GENIE_ENV"] = "dev"
  end
  print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode\n\n")
end

@everywhere go_genie()
@everywhere using Genie

try
  eval(Main, parse("using Genie, Model"))
catch ex
  Genie.log("Can't load modules Genie and Model into Main")
end