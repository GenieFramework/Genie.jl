#!/usr/local/bin/julia --color=yes
module App

push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")))

if ! haskey(ENV, "GENIE_ENV") 
  ENV["GENIE_ENV"] = "dev"
end
include(abspath(joinpath("config", "env", ENV["GENIE_ENV"] * ".jl")))

using Genie

end