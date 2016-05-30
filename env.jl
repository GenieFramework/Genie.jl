# if the environment is not defined, use this
if ! haskey(ENV, "GENIE_ENV") 
  ENV["GENIE_ENV"] = "dev"
end