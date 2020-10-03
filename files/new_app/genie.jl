haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = "dev")
if !haskey(ENV, "HOST")
	ENV["HOST"] = (ENV["GENIE_ENV"] == "dev") ? "127.0.0.1" : "0.0.0.0"
end


### EARLY BIND TO PORT FOR HOSTS WITH TIMEOUT ###

import Sockets

const EARLYBINDING = if haskey(ENV, "EARLYBIND") && lowercase(ENV["EARLYBIND"]) == "true" && haskey(ENV, "PORT")
  printstyled("\nEarly binding to host $(ENV["HOST"]) and port $(ENV["PORT"]) \n", color = :light_blue, bold = true)
  try
    Sockets.listen(parse(Sockets.IPAddr, ENV["HOST"]), parse(Int, ENV["PORT"]))
  catch ex
    @show ex

    printstyled("\nFailed early binding!\n", color = :red, bold = true)
    nothing
  end
else
  nothing
end


### OFF WE GO! ###

using Genie

const ROOT_PATH = pwd()

push!(LOAD_PATH, ROOT_PATH, "src")

Genie.load(context = @__MODULE__)
Genie.run(server = EARLYBINDING)
