cd(@__DIR__)

using Pkg

using Test, TestSetExtensions, SafeTestsets
using Genie

@testset ExtendedTestSet "Genie tests" begin
  @includetests ARGS
end