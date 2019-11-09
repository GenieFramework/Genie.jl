cd(@__DIR__)

using Pkg
pkg"activate ."

using Test, TestSetExtensions, SafeTestsets
using Genie

isdir(joinpath(Genie.config.path_build, Genie.Renderer.Html.BUILD_NAME)) && rm(joinpath(Genie.config.path_build, Genie.Renderer.Html.BUILD_NAME), force = true, recursive = true)

@testset ExtendedTestSet "Genie tests" begin
  @includetests ARGS
end