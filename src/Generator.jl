"""
Generates various Genie files.
"""
module Generator

import Dates, Pkg, Logging, UUIDs
import Inflector
import Genie


const NEW_APP_PATH = joinpath("files", "new_app")


function validname(name::String)
  filter(! isempty, [x.match for x in collect(eachmatch(r"[0-9a-zA-Z_-]*", name))]) |> join
end

"""
    newcontroller(controller_name::Union{String,Symbol}) :: Nothing

Creates a new `controller` file. If `pluralize` is `false`, the name of the controller is not automatically pluralized.
"""
function newcontroller(controller_name::Union{String,Symbol}; path::Union{String,Nothing} = nothing, pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing
  Generator.newcontroller(string(controller_name), path = path, pluralize = pluralize)
  Genie.Loader.load_resources(; context = Genie.Loader.default_context(context))

  nothing
end


"""
    newcontroller(resource_name::String) :: Nothing

Generates a new Genie controller file and persists it to the resources folder.
"""
function newcontroller(resource_name::String; path::Union{String,Nothing} = nothing, pluralize::Bool = true) :: Nothing
  resource_name = validname(resource_name) |> Inflector.from_underscores |> Inflector.from_dashes

  Inflector.is_singular(resource_name) && pluralize && (resource_name = Inflector.to_plural(resource_name))
  resource_name = uppercasefirst(resource_name)

  resource_path = path === nothing ? setup_resource_path(resource_name, path = ".") : (ispath(path) ? path : mkpath(path))
  cfn = controller_file_name(resource_name)
  write_resource_file(resource_path, cfn, resource_name, :controller, pluralize = pluralize) &&
    @info "New controller created at $(abspath(joinpath(resource_path, cfn)))"

  nothing
end


"""
    newresource(resource_name::Union{String,Symbol}; pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing

Creates all the files associated with a new resource.
If `pluralize` is `false`, the name of the resource is not automatically pluralized.
"""
function newresource(resource_name::Union{String,Symbol}; path::String = ".", pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing
  newresource(string(resource_name), path = path, pluralize = pluralize)
  Genie.Loader.load_resources(; context = Genie.Loader.default_context(context))

  nothing
end


"""
    newresource(resource_name::String, config::Settings) :: Nothing

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function newresource(resource_name::String; path::String = ".", pluralize::Bool = true) :: Nothing
  resource_name = validname(resource_name) |> Inflector.from_underscores |> Inflector.from_dashes

  Inflector.is_singular(resource_name) && pluralize &&
    (resource_name = Inflector.to_plural(resource_name))

  resource_path = setup_resource_path(resource_name, path = path)
  for (resource_file, resource_type) in [(controller_file_name(resource_name), :controller)]
    write_resource_file(resource_path, resource_file, resource_name, resource_type, pluralize = pluralize) &&
      @info "New $resource_file created at $(abspath(joinpath(resource_path, resource_file)))"
  end

  views_path = joinpath(resource_path, "views")
  isdir(views_path) || mkpath(views_path)

  nothing
end

"""
    newtask(task_name::Union{String,Symbol}) :: Nothing

Creates a new Genie `Task` file.
"""
function newtask(task_name::Union{String,Symbol}) :: Nothing
  task_name = string(task_name)
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Toolbox.new(task_name)

  nothing
end

###################################


"""
    setup_resource_path(resource_name::String) :: String

Computes and creates the directories structure needed to persist a new resource.
"""
function setup_resource_path(resource_name::String; path::String = ".") :: String
  isdir(Genie.config.path_app) || Genie.Generator.mvc_support(path)

  resource_path = joinpath(path, Genie.config.path_resources, lowercase(resource_name))

  if ! isdir(resource_path)
    mkpath(resource_path)
    push!(LOAD_PATH, resource_path)
  end

  resource_path
end


"""
    write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool

Generates all resource files and persists them to disk.
"""
function write_resource_file(resource_path::String, file_name::String, resource_name::String, resource_type::Symbol; pluralize::Bool = true) :: Bool
  resource_name = (pluralize ? (Inflector.to_plural(resource_name)) : resource_name) |> Inflector.from_underscores |> Inflector.from_dashes

  try
    if resource_type == :controller
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, Genie.FileTemplates.newcontroller(resource_name))
      end
    end
  catch ex
    @error ex
  end

  try
    if resource_type == :test
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        name = pluralize ? (Inflector.to_singular(resource_name)) : resource_name
        write(f, Genie.FileTemplates.newtest(resource_name,  name))
      end
    end
  catch ex
    @error ex
  end

  try
    Genie.Loader.load_resources()
  catch ex
    @error ex
  end

  true
end


function binfolderpath(path::String) :: String
  bin_folder_path = joinpath(path, Genie.config.path_bin)
  isdir(bin_folder_path) || mkpath(bin_folder_path)

  bin_folder_path
end


"""
    setup_windows_bin_files(path::String = ".") :: Nothing

Creates the bin/server and bin/repl binaries for Windows
"""
function setup_windows_bin_files(path::String = ".") :: Nothing
  JULIA_PATH = joinpath(Sys.BINDIR, "julia")
  bin_folder_path = binfolderpath(path)

  open(joinpath(bin_folder_path, "repl.bat"), "w") do f
    write(f, "\"$JULIA_PATH\" --color=yes --depwarn=no --project=@. -q -i -- \"%~dp0..\\$(Genie.BOOTSTRAP_FILE_NAME)\" %*")
  end

  open(joinpath(bin_folder_path, "server.bat"), "w") do f
    write(f, "\"$JULIA_PATH\" --color=yes --depwarn=no --project=@. -q -i -- \"%~dp0..\\$(Genie.BOOTSTRAP_FILE_NAME)\" -s=true %*")
  end

  open(joinpath(bin_folder_path, "runtask.bat"), "w") do f
    write(f, "\"$JULIA_PATH\" --color=yes --depwarn=no --project=@. -q -- \"%~dp0..\\$(Genie.BOOTSTRAP_FILE_NAME)\" -r %*")
  end

  nothing
end


"""
    setup_nix_bin_files(path::String = ".") :: Nothing

Creates the bin/server and bin/repl binaries for *nix systems
"""
function setup_nix_bin_files(path::String = ".") :: Nothing
  bin_folder_path = binfolderpath(path)

  open(joinpath(bin_folder_path, "repl"), "w") do f
    write(f, "#!/bin/sh\n" * raw"julia --color=yes --depwarn=no --project=@. -q -L $(dirname $0)/../bootstrap.jl -- \"$@\"")
  end

  open(joinpath(bin_folder_path, "server"), "w") do f
    write(f, "#!/bin/sh\n" * raw"julia --color=yes --depwarn=no --project=@. -q -i -- $(dirname $0)/../bootstrap.jl -s=true \"$@\"")
  end

  open(joinpath(bin_folder_path, "runtask"), "w") do f
    write(f, "#!/bin/sh\n" * raw"julia --color=yes --depwarn=no --project=@. -q -- $(dirname $0)/../bootstrap.jl -r \"$@\"")
  end

  chmod(joinpath(bin_folder_path, "server"), 0o700)
  chmod(joinpath(bin_folder_path, "repl"), 0o700)
  chmod(joinpath(bin_folder_path, "runtask"), 0o700)

  nothing
end


"""
    resource_does_not_exist(resource_path::String, file_name::String) :: Bool

Returns `true` if the indicated resources does not exists - false otherwise.
"""
function resource_does_not_exist(resource_path::String, file_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    @warn "File already exists, $(joinpath(resource_path, file_name)) - skipping"

    return false
  end

  true
end


"""
    controller_file_name(resource_name::Union{String,Symbol})

Computes the controller file name based on the resource name.
"""
function controller_file_name(resource_name::Union{String,Symbol}) :: String
  GENIE_CONTROLLER_FILE_POSTFIX = "Controller.jl"
  uppercasefirst(string(resource_name)) * GENIE_CONTROLLER_FILE_POSTFIX
end


"""
    write_secrets_file(app_path=".")

Generates a valid `config/secrets.jl` file with a random secret token.
"""
function write_secrets_file(app_path::String = ".") :: Nothing
  secrets_path = joinpath(app_path, Genie.config.path_config)
  ispath(secrets_path) || mkpath(secrets_path)

  open(joinpath(secrets_path, Genie.Secrets.SECRETS_FILE_NAME), "w") do f
    write(f, """Genie.Secrets.secret_token!("$(Genie.Secrets.secret())") """)
  end

  nothing
end


"""
    fullstack_app(app_name::String) :: Nothing

Writes the files necessary to create a full stack Genie app.
"""
function fullstack_app(app_name::String, app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", NEW_APP_PATH), app_path)

  scaffold(app_name, app_path)

  nothing
end


"""
    minimal(app_name::String, app_path::String = abspath(app_name), autostart::Bool = true) :: Nothing

Creates a minimal Genie app.
"""
function minimal(app_name::String, app_path::String = "", autostart::Bool = true) :: Nothing
  app_name = validname(app_name)
  app_path = abspath(app_name)

  scaffold(app_name, app_path)

  post_create(app_name, app_path, autostart = autostart)

  nothing
end


"""
    scaffold(app_name::String, app_path::String = "") :: Nothing

Writes the file necessary to scaffold a minimal Genie app.
"""
function scaffold(app_name::String, app_path::String = "") :: Nothing
  GENIE_FILE_NAME = "genie.jl"

  app_name = validname(app_name)
  app_path = abspath(app_name)

  isdir(app_path) || mkpath(app_path)

  for f in [Genie.config.path_src, GENIE_FILE_NAME, Genie.ROUTES_FILE_NAME,
            ".gitattributes", ".gitignore", ".env.example"]
    try
      cp(joinpath(@__DIR__, "..", NEW_APP_PATH, f), joinpath(app_path, f))
    catch ex
    end
  end

  write_app_custom_files(app_name, app_path)

  nothing
end


"""
    microstack_app(app_name::String, app_path::String = ".") :: Nothing

Writes the file necessary to create a microstack app.
"""
function microstack_app(app_name::String, app_path::String = ".") :: Nothing
  isdir(app_path) || mkpath(app_path)

  for f in [Genie.config.path_bin, Genie.config.path_config, Genie.config.server_document_root]
    cp(joinpath(@__DIR__, "..", NEW_APP_PATH, f), joinpath(app_path, f))
  end

  scaffold(app_name, app_path)

  nothing
end


"""
    mvc_support(app_path::String = ".") :: Nothing

Writes the files used for rendering resources using the MVC stack and the Genie templating system.
"""
function mvc_support(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", NEW_APP_PATH, Genie.config.path_app), joinpath(app_path, Genie.config.path_app))

  nothing
end


"""
    db_support(app_path::String = ".") :: Nothing

Writes files used for interacting with the SearchLight ORM.
"""
function db_support(app_path::String = ".", include_env::Bool = true, add_dependencies::Bool = true;
                    testmode::Bool = false, dbadapter::Union{String,Symbol,Nothing} = nothing, interactive::Bool = true)

  cp(joinpath(@__DIR__, "..", NEW_APP_PATH, Genie.config.path_db), joinpath(app_path, Genie.config.path_db), force = true)

  db_intializer(app_path, include_env)

  add_dependencies ? install_db_dependencies(testmode = testmode, dbadapter = dbadapter, interactive = interactive) : dbadapter
end


function db_intializer(app_path::String = ".", include_env::Bool = false)
  initializers_dir = joinpath(app_path, Genie.config.path_initializers)
  initializer_path = joinpath(initializers_dir, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME)
  source_path = joinpath(@__DIR__, "..", NEW_APP_PATH, Genie.config.path_initializers, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME) |> normpath

  if !isfile(initializer_path)
    ispath(initializers_dir) || mkpath(initializers_dir)
    include_env && cp(joinpath(@__DIR__, "..", NEW_APP_PATH, Genie.config.path_env), joinpath(app_path, Genie.config.path_env), force = true)
    cp(source_path, initializer_path)
  end
end


"""
    write_app_custom_files(path::String, app_path::String) :: Nothing

Writes the Genie app main module file.
"""
function write_app_custom_files(path::String, app_path::String) :: Nothing
  moduleinfo = Genie.FileTemplates.appmodule(path)

  open(joinpath(app_path, Genie.config.path_src, moduleinfo[1] * ".jl"), "w") do f
    write(f, moduleinfo[2])
  end

  open(joinpath(app_path, Genie.BOOTSTRAP_FILE_NAME), "w") do f
    write(f,
    """
    (pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

    using $(moduleinfo[1])
    const UserApp = $(moduleinfo[1])
    $(moduleinfo[1]).main()
    """)
  end

  isdir(joinpath(app_path, "test")) || mkpath(joinpath(app_path, "test"))
  open(joinpath(app_path, "test", "runtests.jl"), "w") do f
    write(f,
      """
      # This file is autogenerated to run all tests in the context of your Genie app.
      # It is not necessary to edit this file.
      # To create tests, simply add `.jl` test files in the `test/` folder.
      # All `.jl` files in the `test/` folder will be automatically executed by running `\$ julia --project runtests.jl`
      # If you want to selectively run tests, use `\$ julia --project runtests.jl test_file_1 test_file_2`

      ENV["GENIE_ENV"] = "test"
      push!(LOAD_PATH, abspath(normpath(joinpath("..", "src"))))

      cd("..")
      using Pkg
      Pkg.activate(".")

      using Genie
      Genie.loadapp()

      cd(@__DIR__)
      Pkg.activate(".")

      # !!! Main.UserApp is configured as an alias for Main.$(moduleinfo[1]) and you might encounter it in some tests
      using Main.$(moduleinfo[1]), Test, TestSetExtensions, Logging

      Logging.global_logger(NullLogger())

      @testset ExtendedTestSet "$(moduleinfo[1]) tests" begin
        @includetests ARGS
      end
      """)
  end

  nothing
end


"""
    install_app_dependencies(app_path::String = ".") :: Nothing

Installs the application's dependencies using Julia's Pkg
"""
function install_app_dependencies(app_path::String = "."; testmode::Bool = false,
                                  dbsupport::Bool = false, dbadapter::Union{String,Symbol,Nothing} = nothing,
                                  interactive::Bool = true)
  @info "Installing app dependencies"
  Pkg.activate(".")

  pkgs = ["Dates", "Logging", "Inflector"]

  testmode ? Pkg.develop("Genie", io = devnull) : Pkg.add(Pkg.PackageSpec(; name="Genie", version="5"))

  Pkg.add(pkgs, io = devnull)

  result = dbsupport ? install_db_dependencies(testmode = testmode, dbadapter = dbadapter, interactive = interactive) : dbadapter

  @info "Installing dependencies for unit tests"

  Pkg.activate("test")

  Pkg.add(Pkg.PackageSpec(; name="Genie", version="5"), io = devnull)
  Pkg.add("Test", io = devnull)
  Pkg.add("TestSetExtensions", io = devnull)
  Pkg.add("Pkg", io = devnull)
  Pkg.add("Logging", io = devnull)
  Pkg.instantiate()

  dbsupport ? install_db_dependencies(testmode = testmode, dbadapter = dbadapter, interactive = interactive) : dbadapter

  Pkg.activate(".") # return to the main project

  result
end


"""
    generate_project(name)

Generate the `Project.toml` with a name and a uuid.
If this file already exists, generate `Project_sample.toml` as a reference instead.
"""
function generate_project(name::String) :: Nothing
  name = Genie.FileTemplates.appmodule(name)[1] # convert to camel case

  mktempdir() do tmpdir
    tmp = joinpath(tmpdir, name, "Project.toml")

    pkgproject(Pkg.API.Context(), name, tmpdir) # generate tmp

    # Pkg.project(Pkg.stdout_f(), name, tmpdir) # generate tmp

    if !isfile("Project.toml")
      mv(tmp, "Project.toml") # move tmp here
      @info "Project.toml has been generated"
    else
      mv(tmp, "Project_sample.toml"; force = true)
      @warn "$(abspath("."))/Project.toml already exists and will not be replaced. " *
        "Make sure that it specifies a name and a uuid, using Project_sample.toml as a reference."
    end
  end # remove tmpdir on completion

  nothing
end


function pkgproject(ctx::Pkg.API.Context, pkg::String, dir::String) :: Nothing
  name = email = nothing

  gitname = Pkg.LibGit2.getconfig("user.name", "")
  isempty(gitname) || (name = gitname)

  gitmail = Pkg.LibGit2.getconfig("user.email", "")
  isempty(gitmail) || (email = gitmail)

  if name === nothing
      for env in ["GIT_AUTHOR_NAME", "GIT_COMMITTER_NAME", "USER", "USERNAME", "NAME"]
          name = get(ENV, env, nothing)
          name !== nothing && break
      end
  end

  name === nothing && (name = "Unknown")

  if email === nothing
      for env in ["GIT_AUTHOR_EMAIL", "GIT_COMMITTER_EMAIL", "EMAIL"];
          email = get(ENV, env, nothing)
          email !== nothing && break
      end
  end

  authors = ["$name " * (email === nothing ? "" : "<$email>")]

  uuid = UUIDs.uuid4()

  pkggenfile(ctx, pkg, dir, "Project.toml") do io
      toml = Dict{String,Any}("authors" => authors,
                              "name" => pkg,
                              "uuid" => string(uuid),
                              "version" => "0.1.0",
                              )
      Pkg.TOML.print(io, toml, sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
  end
end


function pkggenfile(f::Function, ctx::Pkg.API.Context, pkg::String, dir::String, file::String) :: Nothing
  path = joinpath(dir, pkg, file)
  println(ctx.io, "    $(Base.contractuser(path))")
  mkpath(dirname(path))
  open(f, path, "w")
end


function install_db_dependencies(; testmode::Bool = false, dbadapter::Union{String,Symbol,Nothing} = nothing, interactive::Bool = true)
  try
    testmode ? Pkg.develop("SearchLight", io = devnull) : Pkg.add("SearchLight", io = devnull)
    interactive || ! isnothing(dbadapter) ?
      install_searchlight_dependencies(dbadapter, testmode = testmode) :
        dbadapter
  catch ex
    @error ex
  end
end


function install_searchlight_dependencies(dbadapter::Union{String,Symbol,Nothing} = nothing;
                                          testmode::Bool = false) # TODO: move this to SearchLight post install

  adapter::String = if dbadapter === nothing
    backends = ["SQLite", "MySQL", "PostgreSQL"] # TODO: this should be dynamic somehow -- maybe by using the future plugins REST API

    println()
    println("Please choose the DB backend you want to use: ")
    for i in 1:length(backends)
      println("$i. $(backends[i])")
    end
    # println("$(length(backends)+1). Other")
    println("$(length(backends)+1). Skip installing DB support at this time")

    println( "
Input $(join([1:(length(backends)+1)...], ", ", " or ")) and press ENTER to confirm.
If you are not sure what to pick, choose 1 (SQLite). It is the simplest option to get you started right away.
You can add support for additional databases anytime later. ")
    println()

    choice = try
      parse(Int, readline())
    catch
      return install_searchlight_dependencies(; testmode = testmode)
    end

    if choice == (length(backends)+1)
      println("Skipping DB support installation")
      println()

      return
    elseif choice > (length(backends)+1)
      @warn "You must choose a number between 1 and $(length(backends)+1)"
      return install_searchlight_dependencies(; testmode = testmode)
    else
      backends[choice]
    end
  else
    string(dbadapter)
  end

  if adapter != "SQLite"
    @warn "You need to edit the database configuration file at db/connection.yml to set your database connection info."
  end

  testmode ? Pkg.develop("SearchLight$adapter", io = devnull) : Pkg.add("SearchLight$adapter", io = devnull)

  adapter
end


"""
    write_db_config(connfile = joinpath("db", "connection.yml"))

Writes the default configuration for the selected SearchLight DB adapter.
"""
macro write_db_config(connfile = joinpath("db", "connection.yml"),
                      initfile = joinpath("config", "initializers", "searchlight.jl"))
  quote
    isfile($connfile) && chmod($connfile, 0o760)

    open($connfile, "w") do f
      write(f, SearchLight.Generator.FileTemplates.adapter_default_config(database = Genie.config.app_env, env = Genie.config.app_env))
    end

    include($initfile)

    nothing
  end |> esc
end


"""
    autostart_app(path::String = "."; autostart::Bool = true) :: Nothing

If `autostart` is `true`, the newly generated Genie app will be automatically started.
"""
function autostart_app(path::String = "."; autostart::Bool = true, initdb::Bool = false, dbadapter::Union{Nothing,Symbol,String} = nothing) :: Nothing
  if autostart
    @info "Starting your brand new Genie app - hang tight!"
    Genie.loadapp(abspath(path); autostart = autostart, dbadapter = string(dbadapter))
  else
    @info("Your new Genie app is ready!
        Run \njulia> Genie.loadapp() \nto load the app's environment
        and then \njulia> up() \nto start the web server on port 8000.")
  end

  nothing
end


"""
    remove_searchlight_initializer(app_path::String = ".") :: Nothing

Removes the SearchLight initializer file if it's unused
"""
function remove_searchlight_initializer(app_path::String = ".") :: Nothing
  rm(joinpath(app_path, Genie.config.path_initializers, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME), force = true)

  nothing
end


"""
    newapp(app_name::String; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing

Scaffolds a new Genie app, setting up the file structure indicated by the various arguments.

# Arguments
- `app_name::String`: the name of the app (can be the full path where the app should be created).
- `autostart::Bool`: automatically start the app once the file structure is created
- `fullstack::Bool`: the type of app to be bootstrapped. The fullstack app includes MVC structure, DB connection code, and asset pipeline files.
- `dbsupport::Bool`: bootstrap the files needed for DB connection setup via the SearchLight ORM
- `mvcsupport::Bool`: adds the files used for HTML+Julia view templates rendering and working with resources
- `dbadapter::Union{String,Symbol,Nothing} = nothing` : pass the SearchLight database adapter to be used by default
(one of :MySQL, :SQLite, or :PostgreSQL). If `dbadapter` is `nothing`, an adapter will have to be selected interactivel
at the REPL, during the app creation process.

# Examples
```julia-repl
julia> Genie.Generator.newapp("MyGenieApp")
2019-08-06 16:54:15:INFO:Main: Done! New app created at MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Changing active directory to MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Installing app dependencies
 Resolving package versions...
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Project.toml`
  [c43c736e] + Genie v0.10.1
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Manifest.toml`

2019-08-06 16:54:27:INFO:Main: Starting your brand new Genie app - hang tight!
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

┌ Info:
│ Starting Genie in >> DEV << mode
└
[ Info: Logging to file at MyGenieApp/log/dev.log
[ Info: Ready!
2019-08-06 16:54:32:DEBUG:Main: Web Server starting at http://127.0.0.1:8000
2019-08-06 16:54:32:DEBUG:Main: Web Server running at http://127.0.0.1:8000
```
"""
function newapp(app_name::String; autostart::Bool = true, fullstack::Bool = false,
                dbsupport::Bool = false, mvcsupport::Bool = false, testmode::Bool = false,
                dbadapter::Union{String,Symbol,Nothing} = nothing, interactive::Bool = true) :: Nothing
  app_name = validname(app_name)
  app_path = abspath(app_name)

  fullstack ? fullstack_app(app_name, app_path) : microstack_app(app_name, app_path)

  dbadapter = (dbsupport || fullstack) ?
                db_support(app_path; testmode, dbadapter, interactive) :
                  remove_searchlight_initializer(app_path)

  mvcsupport && (fullstack || mvc_support(app_path))

  write_secrets_file(app_path)

  try
    setup_windows_bin_files(app_path)
  catch ex
    @error ex
  end

  try
    setup_nix_bin_files(app_path)
  catch ex
    @error ex
  end

  post_create(app_name, app_path; autostart = autostart, testmode = testmode,
              dbsupport = (dbsupport || fullstack), dbadapter = dbadapter, interactive = interactive)

  nothing
end


function post_create(app_name::String, app_path::String; autostart::Bool = true, testmode::Bool = false,
                      dbsupport::Bool = false, dbadapter::Union{String,Symbol,Nothing} = nothing, interactive::Bool = true) :: Nothing
  @info "Done! New app created at $app_path"

  @info "Changing active directory to $app_path"
  cd(app_path)

  generate_project(app_name)

  dbadapter = install_app_dependencies(app_path, testmode = testmode, dbsupport = dbsupport, dbadapter = dbadapter, interactive = interactive)

  set_files_mod()

  autostart_app(app_path, autostart = autostart, dbadapter = dbadapter)

  nothing
end


function set_files_mod() :: Nothing
  for f in vcat( # TODO: make this DRY
                ["Manifest.toml", "Project.toml", "routes.jl"],
                (isdir("app") ? readdir("app") : []), (isdir("app/helpers") ? readdir("app/helpers"; join = true) : []),
                (isdir("config") ? readdir("config") : []), (isdir("config/env") ? readdir("config/env"; join = true) : []), (isdir("config/initializers") ? readdir("config/initializers"; join = true) : []),
                (isdir("db") ? readdir("db") : []),
                (isdir("public") ? readdir("public") : []),
                (isdir("test") ? readdir("test") : [])
                )
    try
      isfile(f) && chmod(f, 0o760)
    catch err
      @error err
      @warn "Can't change mod for $f. File might be read-only."
    end
  end

  nothing
end


"""
    newapp_webservice(name::String; autostart::Bool = true, dbsupport::Bool = false) :: Nothing

Template for scaffolding a new Genie app suitable for nimble web services.

# Arguments
- `name::String`: the name of the app
- `autostart::Bool`: automatically start the app once the file structure is created
- `dbsupport::Bool`: bootstrap the files needed for DB connection setup via the SearchLight ORM
- `dbadapter::Union{String,Symbol,Nothing} = nothing` : pass the SearchLight database adapter to be used by default
(one of :MySQL, :SQLite, or :PostgreSQL). If `dbadapter` is `nothing`, an adapter will have to be selected interactivel
at the REPL, during the app creation process.
"""
function newapp_webservice(name::String; autostart::Bool = true, dbsupport::Bool = false,
                            dbadapter::Union{String,Symbol,Nothing} = nothing, testmode::Bool = false,
                            interactive::Bool = true) :: Nothing
  newapp(name, autostart = autostart, fullstack = false, dbsupport = dbsupport, mvcsupport = false,
          dbadapter = dbadapter, testmode = testmode, interactive = interactive)
end


"""
    newapp_mvc(name::String; autostart::Bool = true) :: Nothing

Template for scaffolding a new Genie app suitable for MVC web applications (includes MVC structure and DB support).

# Arguments
- `name::String`: the name of the app
- `autostart::Bool`: automatically start the app once the file structure is created
- `dbadapter::Union{String,Symbol,Nothing} = nothing` : pass the SearchLight database adapter to be used by default
(one of :MySQL, :SQLite, or :PostgreSQL). If `dbadapter` is `nothing`, an adapter will have to be selected interactivel
at the REPL, during the app creation process.
"""
function newapp_mvc(name::String; autostart::Bool = true, dbadapter::Union{String,Symbol,Nothing} = nothing,
                    testmode::Bool = false, interactive::Bool = true) :: Nothing
  newapp(name, autostart = autostart, fullstack = false, dbsupport = true, mvcsupport = true, dbadapter = dbadapter,
          testmode = testmode, interactive = interactive)
end


"""
    newapp_fullstack(name::String; autostart::Bool = true) :: Nothing

Template for scaffolding a new Genie app suitable for full stack web applications (includes MVC structure, DB support, and frontend asset pipeline).

# Arguments
- `name::String`: the name of the app
- `autostart::Bool`: automatically start the app once the file structure is created
- `dbadapter::Union{String,Symbol,Nothing} = nothing` : pass the SearchLight database adapter to be used by default
(one of :MySQL, :SQLite, or :PostgreSQL). If `dbadapter` is `nothing`, an adapter will have to be selected interactivel
at the REPL, during the app creation process.
"""
function newapp_fullstack(name::String; autostart::Bool = true, dbadapter::Union{String,Symbol,Nothing} = nothing,
                          testmode::Bool = false, interactive::Bool = true) :: Nothing
  newapp(name, autostart = autostart, fullstack = true, dbsupport = true, mvcsupport = true, dbadapter = dbadapter,
          testmode = testmode, interactive = interactive)
end


function autoconfdb(dbadapter)
  Core.eval(Main, Meta.parse("using SearchLight"))
  Core.eval(Main, Meta.parse("using SearchLight$dbadapter"))

  Core.eval(Main, Meta.parse("Genie.Generator.@write_db_config()"))
end

end
