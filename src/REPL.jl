module REPL

using SHA, Logger, Configuration, SearchLight, Genie, Generator, Tester, Toolbox, App, Migration


"""
    secret_token() :: String

Generates a random secret token to be used for configuring the SECRET_TOKEN const.
"""
function secret_token() :: String
  sha256("$(randn()) $(Dates.now())") |> bytes2hex
end


"""
    new_app(path = ".") :: Void

Creates a new Genie app at the indicated path.
"""
function new_app(path = ".") :: Void
  cp(joinpath(Pkg.dir("Genie"), "files", "new_app"), abspath(path))
  chmod(joinpath(path, "genie.jl"), 0o700)

  open(joinpath(path, "config", "secrets.jl"), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  Logger.log("Done! New app created at $(abspath(path))", :info)

  Logger.log("You must restart the current Julia session before loading the new app to properly reinitialize Genie.", :warn)

  nothing
end


"""
    db_init() :: Bool

Sets up the DB tables used by Genie.
"""
function db_init() :: Bool
  SearchLight.create_migrations_table(Genie.config.db_migrations_table_name)
end


"""
    new_model(model_name) :: Void

Creates a new `model` file.
"""
function new_model(model_name) :: Void
  Generator.new_model(Dict{String,Any}("model:new" => model_name), Settings())
end


"""
    new_controller(controller_name) :: Void

Creates a new `controller` file.
"""
function new_controller(controller_name) :: Void
  Generator.new_controller(Dict{String,Any}("controller:new" => controller_name), Settings())
end


"""
    new_resource(resource_name) :: Void

Creates all the files associated with a new resource.
"""
function new_resource(resource_name) :: Void
  Generator.new_resource(Dict{String,Any}("resource:new" => resource_name), Settings())
end


"""
    new_migration(migration_name) :: Void

Creates a new migration file.
"""
function new_migration(migration_name) :: Void
  Generator.new_migration(Dict{String,Any}("migration:new" => migration_name), Settings())
end

end
