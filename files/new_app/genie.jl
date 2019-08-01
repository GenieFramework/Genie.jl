cd(@__DIR__)
using Pkg
pkg"activate ."

using Revise

"""
    bootstrap_genie() :: Nothing

Bootstraps the Genie framework setting up paths and workers. Invoked automatically.
"""
function bootstrap() :: Nothing
  cd(@__DIR__)
  printstyled("""
   _____         _
  |   __|___ ___|_|___
  |  |  | -_|   | | -_|
  |_____|___|_|_|_|___|

  """, color = :magenta)

  DEFAULT_NWORKERS_REPL = 1
  DEFAULT_NWORKERS_SERVER = 1

  isfile("env.jl") && include("env.jl")
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
  @info "\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode \n\n"

  push!(LOAD_PATH, pwd(), "src")

  nothing
end; bootstrap()

using Genie, Genie.App, Genie.Toolbox

Genie.load(context = @__MODULE__)

Genie.run()