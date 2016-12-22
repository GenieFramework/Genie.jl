module App

using Genie, SearchLight, YAML, Validation


"""
    load_models(dir = Genie.RESOURCE_PATH) :: Void

Loads (includes) all available `model` and `validator` files. The modules are included into the `App` module.
"""
function load_models(dir = Genie.RESOURCE_PATH) :: Void
  dir_contents = readdir(abspath(dir))

  for i in dir_contents
    full_path = joinpath(dir, i)
    if isdir(full_path)
      load_models(full_path)
    else
      if i == Genie.GENIE_MODEL_FILE_NAME
        eval(App, :(include($full_path)))
        isfile(joinpath(dir, Genie.GENIE_VALIDATOR_FILE_NAME)) && eval(Validation, :(include(joinpath($dir, $(Genie.GENIE_VALIDATOR_FILE_NAME)))))
      end
    end
  end

  nothing
end


"""
    load_controller(dir::AbstractString) :: Void

Loads (includes) all available `controller` files. The modules are included into the `App` module.
"""
function load_controller(dir::AbstractString) :: Void
  push!(LOAD_PATH, dir)
  file_path = joinpath(dir, Genie.GENIE_CONTROLLER_FILE_NAME)
  isfile(file_path) && eval(App, :(include($file_path)))

  nothing
end


"""
    export_controllers(controllers::AbstractString) :: Void

Make `controller` modules available autside the `App` module.
"""
function export_controllers(controllers::AbstractString) :: Void
  eval(App, parse("""export $(split(controllers, ".")[1])"""))

  nothing
end


"""
    load_acl(dir::AbstractString) :: Dict{Any,Any}

Loads the ACL file associated with the invoked `controller` and returns the rules.
"""
function load_acl(dir::AbstractString) :: Dict{Any,Any}
  file_path = joinpath(dir, Genie.GENIE_AUTHORIZATOR_FILE_NAME)
  isfile(file_path) ? YAML.load(open(file_path)) : Dict{Any,Any}
end


"""
    load_configurations() :: Void

Loads (includes) the framework's configuration files.
"""
function load_configurations() :: Void
  isfile(abspath("$(Genie.CONFIG_PATH)/loggers.jl")) && include(abspath("$(Genie.CONFIG_PATH)/loggers.jl"))
  isfile(abspath("$(Genie.CONFIG_PATH)/secrets.jl")) && include(abspath("$(Genie.CONFIG_PATH)/secrets.jl"))

  nothing
end


"""
    load_initializers() :: Void

Loads (includes) the framework's initializers.
"""
function load_initializers() :: Void
  dir = abspath(joinpath(Genie.CONFIG_PATH, "initializers"))

  if isdir(dir)
    f = readdir(dir)
    for i in f
      include(joinpath(dir, i))
    end
  end

  nothing
end

load_configurations()
load_initializers()
load_models()

end
