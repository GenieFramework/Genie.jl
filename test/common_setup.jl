cd(@__DIR__)

using Pkg
Pkg.activate(".")

using Test, TestSetExtensions, SafeTestsets, Logging
using Genie


# julia -t auto --project=. -i test/common_setup.jl tests_autoloader.jl
