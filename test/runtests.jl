cd(@__DIR__)

using Pkg

using Test, TestSetExtensions, SafeTestsets, Logging
using Genie

macro includetests(testarg...)
  if length(testarg) == 0
      tests = []
  elseif length(testarg) == 1
      tests = testarg[1]
  else
      error("@includetests takes zero or one argument")
  end

  rootfile = "$(__source__.file)"
  mod = __module__

  quote
      tests = $tests
      rootfile = $rootfile

      if length(tests) == 0
          tests = readdir(dirname(rootfile))
          tests = filter(f->endswith(f, ".jl") && f!= basename(rootfile) && f != "common_setup.jl", tests)
      else
          tests = map(f->string(f, ".jl"), tests)
      end

      println();

      for test in tests
          print(splitext(test)[1], ": ")
          Base.include($mod, test)
          println()
      end
  end
end

Logging.global_logger(NullLogger())

@testset ExtendedTestSet "Genie tests" begin
  @includetests ARGS
end