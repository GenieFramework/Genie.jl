module REPL

using SHA, Logger, Configuration, Genie, Database, Generator, Tester, Toolbox, App, Migration

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
  Logger.log("Done! New app created at $(abspath(path))")

  nothing
end

function db_init() :: Bool
  Database.create_migrations_table()
end

function new_model(model_name) :: Void
  Generator.new_model(Dict{String,Any}("model:new" => model_name), Settings())
end

function new_controller(controller_name) :: Void
  Generator.new_controller(Dict{String,Any}("controller:new" => controller_name), Settings())
end

function new_resource(resource_name) :: Void
  Generator.new_resource(Dict{String,Any}("resource:new" => resource_name), Settings())
end

function new_migration(migration_name) :: Void
  Generator.new_migration(Dict{String,Any}("migration:new" => migration_name), Settings())
end

end
