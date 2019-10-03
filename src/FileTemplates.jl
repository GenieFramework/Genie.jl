"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

using Genie.Inflector


"""
    newtask(module_name::String) :: String

Default content for a new Genie Toolbox task.
"""
function newtask(module_name::String) :: String
  """
  module $module_name

  using Genie, Genie.Toolbox


  \"\"\"
  Description of the task here
  \"\"\"
  function runtask()
    # Build something great
  end

  end
  """
end


"""
    newcontroller(controller_name::String) :: String

Default content for a new Genie controller.
"""
function newcontroller(controller_name::String) :: String
  """
  module $(controller_name)Controller
    # Build something great
  end
  """
end


"""
    newtest(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function newtest(plural_name::String, singular_name::String) :: String
  """
  using Genie, App.$(plural_name)

  ### Your tests here
  @test 1 == 1
  """
end


"""
    appmodule(path::String)

Generates a custom app module when a new app is bootstrapped.
"""
function appmodule(path::String)
  path = replace(path, "-"=>"_") |> strip
  appname = split(path, "/", keepempty = false)[end] |> String |> Inflector.from_underscores

  content = """
  module $appname

  using Logging, LoggingExtras

  function main()
    Base.eval(Main, :(const UserApp = $appname))

    include(joinpath("..", "genie.jl"))

    Base.eval(Main, :(const Genie = $appname.Genie))
    Base.eval(Main, :(using Genie))
  end; main()

  end
  """

  (appname, content)
end


function runtests()
  """
  isdefined(Main, :UserApp) || include(normpath(joinpath("..", "bootstrap.jl")))

  using Revise
  using Test
  using Genie, Genie.Tester, Genie.Router

  current_env = Genie.config.app_env

  Tester.setenv()

  @testset "Integration testing" begin
    # awesome tests here
  end

  Tester.setenv(current_env)
  """
end


function dockerfile(; user::String = "genie", supervisor::Bool = false, nginx::Bool = false, env::String = "dev",
                      filename::String = "Dockerfile", port::Int = 8000, dockerport::Int = 80)
  appdir = "/home/$user/app"

  """
  FROM julia:latest

  # user
  RUN useradd --create-home --shell /bin/bash $user

  # app
  RUN mkdir $appdir
  COPY . $appdir
  WORKDIR $appdir

  RUN chown $user:$user -R *

  RUN chmod +x bin/repl
  RUN chmod +x bin/server
  RUN chmod +x bin/serverinteractive

  USER $user

  RUN julia -e "using Pkg; pkg\\"activate . \\"; pkg\\"instantiate\\"; pkg\\"precompile\\"; "

  # ports
  EXPOSE $port
  EXPOSE $dockerport

  ENV JULIA_DEPOT_PATH "/home/$user/.julia"
  ENV GENIE_ENV "$env"

  CMD ["bin/server"]
  """
end

end