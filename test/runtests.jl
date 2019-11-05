using Pkg
pkg"activate .."

using Test
using Genie, Genie.Tester

isdir(joinpath(Genie.BUILD_PATH, Genie.Renderer.Html.BUILD_NAME)) && rm(joinpath(Genie.BUILD_PATH, Genie.Renderer.Html.BUILD_NAME), force = true, recursive = true)

include("runtests_basicrendering.jl")
include("runtests_rendering.jl")
include("runtests_varsrendering.jl")