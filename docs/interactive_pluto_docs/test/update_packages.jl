#= Update all packages in notebooks to most recently tagged =# 

using Pkg
Pkg.activate(@__DIR__)

using Pluto

notebooks=["nbproto.jl",
           "api-update.jl",
           "flux-reconstruction.jl",
           "problemcase.jl"
           ]


for notebook in notebooks
    println("Updating packages in $(notebook):")
    Pluto.activate_notebook_environment(joinpath(@__DIR__,notebook))
    Pkg.status()
    Pkg.update()
    Pkg.status()
    println("Updating of  $(notebook) done\n")
    Pkg.activate(@__DIR__)
end