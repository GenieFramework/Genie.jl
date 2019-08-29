using Revise
using Genie, Genie.App, Genie.Toolbox

const ROOT_PATH = pwd()

haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
push!(LOAD_PATH, pwd(), "src")

Genie.load(context = @__MODULE__)
Genie.run()