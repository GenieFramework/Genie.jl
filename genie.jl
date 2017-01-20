#!/usr/bin/env julia --color=yes --depwarn=no --math-mode=fast

"""
    bootstrap_genie() :: Void

Bootstraps the Genie framework setting up paths and workers. Invoked automatically.
"""
function bootstrap_genie() :: Void
  dirname(@__FILE__) |> cd
  include(abspath(joinpath("lib", "Genie", "src", "branding.jl")))

  const DEFAULT_NWORKERS_REPL = 1
  const DEFAULT_NWORKERS_SERVER = 4

  isfile("env.jl") && include("env.jl")
  ! haskey(ENV, "GENIE_ENV") && (ENV["GENIE_ENV"] = "dev")
  in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = DEFAULT_NWORKERS_SERVER : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = DEFAULT_NWORKERS_REPL )
  print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n")

  nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())

  @everywhere push!(LOAD_PATH,  abspath(joinpath("lib", "Genie", "src")),
                                abspath(joinpath("lib", "SearchLight", "src")),
                                abspath(joinpath("lib", "Ejl", "src")),
                                abspath(joinpath("lib", "Flax", "src")),
                                abspath(pwd()))
end

@everywhere bootstrap_genie()

@everywhere import Genie
using Genie, App, SearchLight

try
  using OhMyREPL
end
