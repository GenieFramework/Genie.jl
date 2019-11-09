using Test, TestSetExtensions, SafeTestsets
using Genie

isdir(joinpath(Genie.config.path_build, Genie.Renderer.Html.BUILD_NAME)) && rm(joinpath(Genie.config.path_build, Genie.Renderer.Html.BUILD_NAME), force = true, recursive = true)

cd(@__DIR__)

@testset ExtendedTestSet "Genie tests" begin
  @includetests ARGS
end