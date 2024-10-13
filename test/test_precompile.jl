using Pkg
Pkg.activate(".") 

cd("test")

ENV["PRECOMPILE"] = true

using Genie

