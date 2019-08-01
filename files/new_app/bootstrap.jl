cd(@__DIR__)
using Pkg
pkg"activate ."

push!(LOAD_PATH, pwd(), "src")

function main()
  include(joinpath("src", "Static.jl"))
end; main()
