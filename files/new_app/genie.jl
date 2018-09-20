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
  printstyled("\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode \n\n", color = :green)

  push!(LOAD_PATH, pwd(), "src")

  nothing
end

bootstrap()

include(joinpath("src", "App.jl")); using .App
include(joinpath("src", "Toolbox.jl")); using .Toolbox

using Genie

Core.eval(Genie, Meta.parse("""push!(LOAD_PATH, joinpath($(repr(pwd())), "src"))"""))
Core.eval(Genie, Meta.parse("""const ROOT_PATH = $(repr(pwd())) """))
Core.eval(Genie, Meta.parse("const App = $(@__MODULE__).App"))
Core.eval(Genie, Meta.parse("const Toolbox = $(@__MODULE__).Toolbox"))

load()

Core.eval(Genie, Meta.parse("config = App.config"))
Core.eval(Genie, Meta.parse("""const SECRET_TOKEN = "$(secret_token())" """))
Core.eval(Genie, Meta.parse("""const ASSET_FINGERPRINT = "$(App.ASSET_FINGERPRINT)" """))

Genie.run()

using OhMyREPL
OhMyREPL.input_prompt!( "genie>", :blue)
OhMyREPL.output_prompt!("genie>", :cyan)
