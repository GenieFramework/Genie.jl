using Distributed

"""
    bootstrap_genie() :: Nothing

Bootstraps the Genie framework setting up paths and workers. Invoked automatically.
"""
function bootstrap_genie() :: Nothing
  dirname(@__FILE__) |> cd
  printstyled("""
  _____         _
  |   __|___ ___|_|___
  |  |  | -_|   | | -_|
  |_____|___|_|_|_|___|

  """, color = :magenta)

  const DEFAULT_NWORKERS_REPL = 1
  const DEFAULT_NWORKERS_SERVER = 1

  isfile("env.jl") && include("env.jl")
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
  in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = DEFAULT_NWORKERS_SERVER : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = DEFAULT_NWORKERS_REPL )
  printstyled("\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n", color = :green)

  nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())

  @everywhere push!(LOAD_PATH, joinpath("lib"), abspath(pwd()))
end

@everywhere bootstrap_genie()
@everywhere import Genie, App
using App
App.@dependencies

@everywhere Genie.run()

try
  using OhMyREPL

  OhMyREPL.input_prompt!( "genie>", :blue)
  OhMyREPL.output_prompt!("genie>", :cyan)
end