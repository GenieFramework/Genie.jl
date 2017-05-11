"""
Functionality for authenticating Genie users.
"""
module Authentication

using SearchLight, App, Genie, Sessions

export current_user, current_user!!

const USER_ID_KEY = :__auth_user_id


"""
    authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
    authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session

Stores the user id on the session.
"""
function authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
  Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session
  authenticate(user_id, params[:SESSION])
end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session

Removes the user id from the session.
"""
function deauthenticate(session) :: Sessions.Session
  Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
  deauthenticate(params[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session) :: Bool
  Sessions.is_set(session, USER_ID_KEY)
end
function is_authenticated(params::Dict{Symbol,Any}) :: Bool
  is_authenticated(params[:SESSION])
end


"""
    get_authentication(session) :: Nullable
    get_authentication(params::Dict{Symbol,Any}) :: Nullable

Returns the user id stored on the session, if available.
"""
function get_authentication(session) :: Nullable
  Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict{Symbol,Any}) :: Nullable
  get_authentication(params[:SESSION])
end


"""
    login(user, session) :: Nullable{Sessions.Session}
    login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}

Persists on session the id of the user object and returns the session.
"""
function login(user, session) :: Nullable{Sessions.Session}
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable{Sessions.Session}
end
function login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}
  login(user, params[:SESSION])
end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session) :: Sessions.Session
  deauthenticate(session)
end
function logout(params::Dict{Symbol,Any}) :: Sessions.Session
  logout(params[:SESSION])
end


"""
    current_user(session) :: Nullable{User}
    current_user(params::Dict{Symbol,Any}) :: Nullable{User}

Returns the `User` instance corresponding to the currently authenticated user, wrapped into a Nullable.
"""
function current_user(session) :: Nullable{User}
  auth_state = Authentication.get_authentication(session)
  if isnull(auth_state)
    Nullable{User}()
  else
    SearchLight.find_one(User, Base.get(auth_state))
  end
end
function current_user(params::Dict{Symbol,Any}) :: Nullable{User}
  current_user(params[:SESSION])
end


"""
    current_user!!(session) :: User
    current_user!!(params::Dict{Symbol,Any}) :: User

Attempts to get the `User` instance corresponding to the currently authenticated user - throws error on failure.
"""
function current_user!!(session) :: User
  try
    current_user(session) |> Base.get
  catch ex
    Logger.log("The current user is not authenticated", :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end
function current_user!!(params::Dict{Symbol,Any}) :: User
  current_user!!(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session)
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict{Symbol,Any})
  without_authentication(f, params[:SESSION])
end


"""
Sets up files and migrations needed by the Authentication module
"""
module FileTemplates

using Genie

function users_migration() :: String
  """
  module CreateTableUsers

  using Genie, SearchLight

  function up()
    SearchLight.query("CREATE SEQUENCE users__seq_id")
    SearchLight.query("
      CREATE TABLE IF NOT EXISTS users (
        id            integer CONSTRAINT users__idx_id PRIMARY KEY DEFAULT NEXTVAL('users__seq_id'),
        name          varchar(100) NOT NULL,
        email         varchar(100) NOT NULL,
        password      varchar(256) NOT NULL,
        role_id       integer DEFAULT NULL,
        CONSTRAINT users__idx_name UNIQUE(email)
      )
    ")
    SearchLight.query("ALTER SEQUENCE users__seq_id OWNED BY users.id")
    SearchLight.query("CREATE INDEX users__idx_role_id ON users (role_id)")
  end

  function down()
    SearchLight.query("DROP INDEX users__idx_role_id")
    SearchLight.query("DROP INDEX users__seq_id")
    SearchLight.query("DROP TABLE users")
  end

  end
  """
end

function roles_migration() :: String
  """
  module CreateTableRoles

  using Genie, SearchLight

  function up()
    SearchLight.query("CREATE SEQUENCE roles__seq_id")
    SearchLight.query("
      CREATE TABLE IF NOT EXISTS roles (
        id            integer CONSTRAINT roles__idx_id PRIMARY KEY DEFAULT NEXTVAL('roles__seq_id'),
        name          varchar(20) NOT NULL,
        CONSTRAINT    roles__idx_id UNIQUE(id),
        CONSTRAINT    roles__idx_name UNIQUE(name)
      )
    ")
    SearchLight.query("ALTER SEQUENCE roles__seq_id OWNED BY roles.id")
  end

  function down()
    SearchLight.query("DROP INDEX roles__seq_id")
    SearchLight.query("DROP TABLE roles")
  end

  end
  """
end

function routes() :: String
  """
  # Authentication
  route("/login", "user_sessions#UserSessionsController.show_login", named = :show_login)
  route("/login", "user_sessions#UserSessionsController.login", method = POST, named = :login)
  route("/logout", "user_sessions#UserSessionsController.logout", named = :logout)
  """
end

end # module FileTemplates


"""
File generation functionality for the Authentication module.
"""
module Generator

using Migration, Authentication, Logger, Genie, Router

function setup() :: Void
  Logger.log("Creating migrations")
  Migration.new("create_table_users", Authentication.FileTemplates.users_migration())
  Migration.new("create_table_roles", Authentication.FileTemplates.roles_migration())

  Logger.log("Creating paths")
  try
    mkpath(joinpath(Genie.APP_PATH, "layouts"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "layouts")) already exists. Skipping.", :warn)
  end
  try
    mkpath(joinpath(Genie.APP_PATH, "resources", "roles"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "roles")) already exists. Skipping.", :warn)
  end
  try
    mkpath(joinpath(Genie.APP_PATH, "resources", "users"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "users")) already exists. Skipping.", :warn)
  end
  try
    mkpath(joinpath(Genie.APP_PATH, "resources", "user_sessions"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "user_sessions")) already exists. Skipping.", :warn)
  end

  Logger.log("Copying files")
  try
    cp(joinpath(Pkg.dir("Genie"), "files", "authentication", "app", "layouts", "login.flax.html"), joinpath(Genie.APP_PATH, "layouts", "login.flax.html"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "layouts", "login.flax.html")) already exists. Skipping.", :warn)
  end
  try
    cp(joinpath(Pkg.dir("Genie"), "files", "authentication", "app", "resources", "roles", "model.jl"), joinpath(Genie.APP_PATH, "resources", "roles", "model.jl"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "roles", "model.jl")) already exists. Skipping.", :warn)
  end
  try
    cp(joinpath(Pkg.dir("Genie"), "files", "authentication", "app", "resources", "users", "model.jl"), joinpath(Genie.APP_PATH, "resources", "users", "model.jl"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "users", "model.jl")) already exists. Skipping.", :warn)
  end
  try
    cp(joinpath(Pkg.dir("Genie"), "files", "authentication", "app", "resources", "user_sessions", "controller.jl"), joinpath(Genie.APP_PATH, "resources", "user_sessions", "controller.jl"))
  catch ex
    Logger.log("Destination $(joinpath(Genie.APP_PATH, "resources", "user_sessions", "controller.jl")) already exists. Skipping.", :warn)
  end

  Logger.log("Appending routes")
  Router.append_to_routes_file(Authentication.FileTemplates.routes())

  Logger.log("Success!")

  nothing
end

end # module Generator

end
