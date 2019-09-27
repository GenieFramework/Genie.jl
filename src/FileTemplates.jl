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

  using Genie, Genie.Router, Genie.Renderer, Genie.AppServer
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

  # dependencies
  RUN apt-get update
  $(supervisor ?
  "

  # supervisor
  apt-get install -y supervisor
  COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

  " :
  ""
  )
  $(nginx ?
  "
  # nginx
  RUN apt-get install -y nginx
  RUN service nginx start

  " :
  ""
  )
  # user
  RUN useradd --create-home --shell /bin/bash $user
  USER $user

  # app
  RUN mkdir $appdir
  COPY . $appdir
  WORKDIR $appdir
  RUN julia -e "using Pkg; pkg\\"activate . \\"; pkg\\"instantiate\\"; pkg\\"precompile\\"; "

  # PORTS
  EXPOSE $port
  EXPOSE $dockerport

  $(supervisor ?
  "
  # start app via supervisor
  CMD [\"/usr/bin/supervisord\"]
  " :
  "
  # start app via Julia
  CMD [\"/bin/bash -c 'GENIE_ENV=$env julia --color=yes --depwarn=no -q -i -- bootstrap.jl --server:host=0.0.0.0 s'\"]
  "
  )
  """
end

end