using Revise

haskey(ENV, "HOST") || (ENV["HOST"] = "0.0.0.0")
haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")

### EARLY BIND TO PORT FOR HOSTS WITH TIMEOUT ###

using Sockets

const EARLYBINDING = if haskey(ENV, "EARLYBIND") && lowercase(ENV["EARLYBIND"]) == "true" && haskey(ENV, "PORT")
  printstyled("\nEarly binding to host $(ENV["HOST"]) and port $(ENV["PORT"]) \n", color = :light_blue, bold = true)
  try
    Sockets.listen(parse(IPAddr, ENV["HOST"]), parse(Int, ENV["PORT"]))
  catch ex
    @show ex

    printstyled("\nFailed early binding!\n", color = :red, bold = true)
    nothing
  end
else
  nothing
end


### OFF WE GO! ###

using Genie, Genie.App, Genie.Toolbox

const ROOT_PATH = pwd()

push!(LOAD_PATH, ROOT_PATH, "src")

Genie.load(context = @__MODULE__)
Genie.run(server = EARLYBINDING)