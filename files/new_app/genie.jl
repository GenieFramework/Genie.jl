using Distributed
<<<<<<< HEAD
=======
@everywhere using Revise
>>>>>>> 121e5b1ee614140290df165d8401dd3701579b48

"""
    bootstrap_genie() :: Nothing

Bootstraps the Genie framework setting up paths and workers. Invoked automatically.
"""
<<<<<<< HEAD
function bootstrap_genie() :: Nothing
  dirname(@__FILE__) |> cd
  printstyled("""
  _____         _
=======
function bootstrap() :: Nothing
  cd(@__DIR__)
  printstyled("""
   _____         _
>>>>>>> 121e5b1ee614140290df165d8401dd3701579b48
  |   __|___ ___|_|___
  |  |  | -_|   | | -_|
  |_____|___|_|_|_|___|

  """, color = :magenta)

  DEFAULT_NWORKERS_REPL = 1
  DEFAULT_NWORKERS_SERVER = 1

  isfile("env.jl") && include("env.jl")
  haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
  in("s", ARGS) && ! haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] = DEFAULT_NWORKERS_SERVER : ( haskey(ENV, "NWORKERS") ? ENV["NWORKERS"] : ENV["NWORKERS"] = DEFAULT_NWORKERS_REPL )
  printstyled("\nStarting Genie in >> $(ENV["GENIE_ENV"] |> uppercase) << mode using $(ENV["NWORKERS"]) worker(s) \n\n", color = :green)

  nworkers() < parse(Int, ENV["NWORKERS"]) && addprocs(parse(Int, ENV["NWORKERS"]) - nworkers())
  @everywhere push!(LOAD_PATH, pwd(), "src")

<<<<<<< HEAD
  @everywhere push!(LOAD_PATH, joinpath("lib"), abspath(pwd()))
end

@everywhere bootstrap_genie()
@everywhere import Genie, App
using App
App.@dependencies
=======
  nothing
end

@everywhere begin
  bootstrap()
  using Genie, App, Toolbox
>>>>>>> 121e5b1ee614140290df165d8401dd3701579b48

  eval(Genie, Meta.parse("const App = $(@__MODULE__).App"))
  eval(Genie, Meta.parse("const Toolbox = $(@__MODULE__).Toolbox"))
  App.load()

  eval(Genie, Meta.parse("const config = App.config"))
  eval(Genie, Meta.parse("""const SECRET_TOKEN = "$(App.secret_token())" """))
  eval(Genie, Meta.parse("""const ASSET_FINGERPRINT = "$(App.ASSET_FINGERPRINT)" """))

  Genie.run()
end

try
  using OhMyREPL

  OhMyREPL.input_prompt!( "genie>", :blue)
  OhMyREPL.output_prompt!("genie>", :cyan)
<<<<<<< HEAD
=======
catch

>>>>>>> 121e5b1ee614140290df165d8401dd3701579b48
end