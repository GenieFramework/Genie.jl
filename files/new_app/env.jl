# if the environment is not defined, use this
if ! haskey(ENV, "GENIE_ENV")
  ENV["GENIE_ENV"] = "dev"
end
if ! haskey(ENV, "NWORKERS") && in("s", ARGS)
  ENV["NWORKERS"] = 1
end
