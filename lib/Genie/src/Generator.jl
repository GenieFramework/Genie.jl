module Generator

using Genie
using FileTemplates
using Inflector
using Configuration
using Migration

function new_model(cmd_args::Dict{AbstractString,Any}, config::Configuration.Config)
  resource_name = ucfirst(cmd_args["model:new"])
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  write_resource_file(resource_path, Genie.GENIE_MODEL_FILE_NAME, resource_name) &&
    Logger.log("New model created at $(joinpath(resource_path, Genie.GENIE_MODEL_FILE_NAME))")
end

function new_resource(cmd_args::Dict{AbstractString,Any}, config::Configuration.Config)
  cmd_args["model:new"] = ucfirst(Inflector.to_singular(cmd_args["resource:new"]) |> Base.get)
  new_model(cmd_args, config)

  resource_name = ucfirst(cmd_args["resource:new"])
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  cmd_args["migration:new"] = "create_table_" * lowercase(resource_name)
  Migration.new(cmd_args, config)

  resource_path = setup_resource_path(resource_name)
  for resource_file in [Genie.GENIE_CONTROLLER_FILE_NAME]
    write_resource_file(resource_path, resource_file, resource_name) &&
      Logger.log("New file created at $(joinpath(resource_path, resource_file))")
  end

  if ! isdir(joinpath(resource_path, "views"))
    mkpath(joinpath(resource_path, "views"))
  end
end

function setup_resource_path(resource_name::AbstractString)
  resources_dir = abspath(joinpath("app", "resources"))
  resource_path = joinpath(resources_dir, lowercase(resource_name))

  if ! isdir(resource_path)
    mkpath(resource_path)
  end

  resource_path
end

function write_resource_file(resource_path::AbstractString, file_name::AbstractString, resource_name::AbstractString)
  if isfile(joinpath(resource_path, file_name))
    Logger.log("File already exists, $(joinpath(resource_path, file_name)) - skipping", :err)
    return false
  end

  f = open(joinpath(resource_path, file_name), "w")

  if file_name == Genie.GENIE_MODEL_FILE_NAME
    write(f, FileTemplates.new_model( Base.get(Inflector.to_singular( Inflector.from_underscores(resource_name) )) ))
  elseif file_name == Genie.GENIE_CONTROLLER_FILE_NAME
    write(f, FileTemplates.new_controller( Base.get(Inflector.to_plural( Inflector.from_underscores(resource_name) )) ))
  elseif file_name == Genie.GENIE_VALIDATOR_FILE_NAME
    write(f, FileTemplates.new_validator( Base.get(Inflector.to_singular(resource_name)) ))
  elseif file_name == Genie.GENIE_AUTHORIZATOR_FILE_NAME
    write(f, FileTemplates.new_authorizer( Base.get(Inflector.to_singular(resource_name)) ))
  else
    error("Not supported, $file_name")
  end

  close(f)

  true
end

end