cd(@__DIR__)

using Pkg

using Test, TestSetExtensions, SafeTestsets, Logging
using Genie

Logging.global_logger(NullLogger())

@testset ExtendedTestSet "Genie tests" begin
  @includetests ARGS
end