"""
    bootstrap_genie() :: Void

Bootstraps the Genie framework setting up paths and workers. Invoked automatically.
"""
function bootstrap_genie() :: Void
  dirname(@__FILE__) |> cd
  include(joinpath(Pkg.dir("Genie"), "src", "branding.jl"))

  const DEFAULT_NWORKERS_REPL = 1
  const DEFAULT_NWORKERS_SERVER = 1

  isfile("env.jl") && include("env.jl")
  ! haskey(ENV, "GENIE_ENV") && (ENV["GENIE_ENV"] = "dev")
  in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = DEFAULT_NWORKERS_SERVER : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = DEFAULT_NWORKERS_REPL )
  print_with_color(:green, "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n")

  nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())

  @everywhere push!(LOAD_PATH,  joinpath("lib"),
                                joinpath(Pkg.dir("Genie"), "src"),
                                joinpath(Pkg.dir("SearchLight"), "src"),
                                joinpath(Pkg.dir("Flax"), "src"),
                                abspath(pwd()))
end

@everywhere bootstrap_genie()
@everywhere import Genie, App
using App
App.@dependencies

@everywhere Genie.run()

try
  using OhMyREPL

  OhMyREPL.input_prompt!("genie>", :magenta)
  OhMyREPL.output_prompt!("genie>", :white)
end
