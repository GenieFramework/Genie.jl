#!/usr/bin/env julia --color=yes
dirname(@__FILE__) |> cd
push!(LOAD_PATH, abspath(joinpath("lib", "Genie", "src")), abspath(pwd()))
include("App.jl")
using App