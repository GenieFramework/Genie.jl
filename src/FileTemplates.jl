"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

import Inflector


"""
    newtask(module_name::String) :: String

Default content for a new Genie Toolbox task.
"""
function newtask(module_name::String) :: String
  """
  module $module_name

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
  path = replace(path, '-'=>'_') |> strip
  appname = split(path, '/', keepempty = false)[end] |> String |> Inflector.from_underscores

  content = """
  module $appname

  using Genie, Logging, LoggingExtras

  function main()
    Core.eval(Main, :(const UserApp = \$(@__MODULE__)))

    Genie.genie(; context = @__MODULE__)

    Core.eval(Main, :(const Genie = UserApp.Genie))
    Core.eval(Main, :(using Genie))
  end

  end
  """

  (appname, content)
end


"""
    dockerfile(; user::String = "genie", supervisor::Bool = false, nginx::Bool = false, env::String = "dev",
                      filename::String = "Dockerfile", port::Int = 8000, dockerport::Int = 80, host::String = "0.0.0.0",
                      websockets_port::Int = port, websockets_dockerport::Int = dockerport)

Generates dockerfile for the Genie app.
"""
function dockerfile(; user::String = "genie", supervisor::Bool = false, nginx::Bool = false, env::String = "dev",
                      filename::String = "Dockerfile", port::Int = Genie.config.server_port, dockerport::Int = 80,
                      host::String = "0.0.0.0", websockets_port::Int = port, platform::String = "",
                      websockets_dockerport::Int = dockerport, earlybind::Bool = true)
  appdir = "/home/$user/app"

  string(
  """
  # pull latest julia image
  FROM $(isempty(platform) ? "" : "--platform=$platform") julia:latest

  # create dedicated user
  RUN useradd --create-home --shell /bin/bash $user

  # set up the app
  RUN mkdir $appdir
  COPY . $appdir
  WORKDIR $appdir

  # configure permissions
  RUN chown $user:$user -R *

  RUN chmod +x bin/repl
  RUN chmod +x bin/server
  RUN chmod +x bin/runtask

  # switch user
  USER $user

  # instantiate Julia packages
  RUN julia -e "using Pkg; Pkg.activate(\\".\\"); Pkg.instantiate(); Pkg.precompile(); "

  # ports
  EXPOSE $port
  EXPOSE $dockerport
  """,

  (websockets_port != port ?
  """

  # websockets ports
  EXPOSE $websockets_port
  EXPOSE $websockets_dockerport
  """ : ""),

  """

  # set up app environment
  ENV JULIA_DEPOT_PATH "/home/$user/.julia"
  ENV GENIE_ENV "$env"
  ENV HOST "$host"
  ENV PORT "$port"
  ENV WSPORT "$websockets_port"
  ENV EARLYBIND "$earlybind"
  """,

  """

  # run app
  CMD ["bin/server"]

  # or maybe include a Julia file
  # CMD julia -e 'using Pkg; Pkg.activate("."); include("IrisClustering.jl"); '
  """)
end

end
