module App
using Genie, SearchLight, Validation, YAML

function load_models(dir = Genie.RESOURCE_PATH)
  dir_contents = readdir(abspath(dir))

  for i in dir_contents
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_models(full_path)
    else
      if i == Genie.GENIE_MODEL_FILE_NAME
        eval(App, parse("""include("$full_path")"""))
        isfile(joinpath(dir, Genie.GENIE_VALIDATOR_FILE_NAME)) && eval(Validation, :(include(joinpath($dir, $(Genie.GENIE_VALIDATOR_FILE_NAME)))))
      end
    end
  end
end

function load_controller(dir::AbstractString)
  push!(LOAD_PATH, dir)
  file_path = joinpath(dir, Genie.GENIE_CONTROLLER_FILE_NAME)
  isfile(file_path) && eval(App, parse("""include("$file_path")"""))
end

function export_controllers(controllers::AbstractString)
  parts = split(controllers, ".")
  eval(App, parse("export $(parts[1])"))
end

function load_acl(dir::AbstractString)
  file_path = joinpath(dir, Genie.GENIE_AUTHORIZATOR_FILE_NAME)
  isfile(file_path) ? YAML.load(open(file_path)) : Dict{Any,Any}
end

function load_configurations()
  include(abspath("config/loggers.jl"))
  isfile(abspath("config/secrets.jl")) && include(abspath("config/secrets.jl"))
end

function load_initializers()
  dir = abspath(joinpath(Genie.CONFIG_PATH, "initializers"))

  if isdir(dir)
    f = readdir(dir)
    for i in f
      include(joinpath(dir, i))
    end
  end
end

load_configurations()
load_initializers()
load_models()

end