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

end
