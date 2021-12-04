module Deploy


function run(command::Cmd)
  try Base.run(command)

  catch ex
    if isa(ex, Base.IOError)
      @error "Can not find $(command.exec[1]). Please make sure that $(command.exec[1]) is installed and accessible."
    end

    rethrow(ex)
  end
end


module Docker

import Genie, Genie.FileTemplates

DOCKER(; sudo::Bool = Sys.islinux()) = (sudo ? `sudo docker` : `docker`)

"""
    dockerfile(path::String = "."; user::String = "genie", env::String = "dev",
              filename::String = "Dockerfile", port::Int = 8000, dockerport::Int = 80, force::Bool = false)

Generates a `Dockerfile` optimised for containerizing Genie apps.

# Arguments
- `path::String`: where to generate the file
- `filename::String`: the name of the file (default `Dockerfile`)
- `user::String`: the name of the system user under which the Genie app is run
- `env::String`: the environment in which the Genie app will run
- `host::String`: the local IP of the Genie app inside the container
- `port::Int`: the port of the Genie app inside the container
- `dockerport::Int`: the port to use on the host (used by the `EXPOSE` directive)
- `force::Bool`: if the file already exists, when `force` is `true`, it will be overwritten
"""
function dockerfile(path::String = "."; filename::String = "Dockerfile", user::String = "genie", env::String = "dev",
                    host = "0.0.0.0", port::Int = 8000, dockerport::Int = 80, force::Bool = false, platform::String = "linux/amd64",
                    websockets_port::Int = port, websockets_dockerport::Int = dockerport, earlybind::Bool = true)
  filename = normpath(joinpath(path, filename))
  isfile(filename) && force && rm(filename)
  isfile(filename) && error("File $(filename) already exists. Use the `force = true` option to overwrite the existing file.")

  open(filename, "w") do io
    write(io, FileTemplates.dockerfile(user = user, env = env, filename = filename, host = host,
                                        port = port, dockerport = dockerport, platform = platform,
                                        websockets_port = websockets_port, websockets_dockerport = websockets_dockerport))
  end

  "Docker file successfully written at $(abspath(filename))" |> println
end


"""
    build(path::String = "."; appname = "genie")

Builds the Docker image based on the `Dockerfile`
"""
function build(path::String = "."; appname::String = "genie", nocache::Bool = true, sudo::Bool = Sys.islinux())
  if nocache
    `$(DOCKER(sudo = sudo)) build --no-cache -t "$appname" $path`
  else
    `$(DOCKER(sudo = sudo)) build -t "$appname" $path`
  end |> Genie.Deploy.run

  "Docker container successfully built" |> println
end


"""
    run(; containername::String = "genieapp", hostport::Int = 80, containerport::Int = 8000, appdir::String = "/home/genie/app",
        mountapp::Bool = false, image::String = "genie", command::String = "bin/server", rm::Bool = true, it::Bool = true)

Runs the Docker container named `containername`, binding `hostport` and `containerport`.

# Arguments
- `containername::String`: the name of the container of the Genie app
- `hostport::Int`: port to be used on the host for accessing the app
- `containerport::Int`: the port on which the app is running inside the container
- `appdir::String`: the folder where the app is stored within the container
- `mountapp::String`: if true the app from the host will be mounted so that changes on the host will be reflected when accessing the app in the container (to be used for dev)
- `image::String`: the name of the Docker image
- `command::String`: what command to run when starting the app
- `rm::Bool`: removes the container upon exit
- `it::Bool`: runs interactively
"""
function run(; containername::String = "genieapp", hostport::Int = 80, containerport::Int = 8000, appdir::String = "/home/genie/app",
                mountapp::Bool = false, image::String = "genie", command::String = "", rm::Bool = true, it::Bool = true,
                websockets_hostport::Int = hostport, websockets_containerport::Int = containerport, sudo::Bool = Sys.islinux())
  options = []

  it && push!(options, "-it")
  rm && push!(options, "--rm")

  push!(options, "-p")
  push!(options, "$hostport:$containerport")

  if websockets_hostport != hostport || websockets_containerport != containerport
    push!(options, "-p")
    push!(options, "$websockets_hostport:$websockets_containerport")
  end

  push!(options, "--name")
  push!(options, "$containername")

  if mountapp
    push!(options, "-v")
    push!(options,  "$(pwd()):$appdir")
  end

  push!(options, image)

  isempty(command) || push!(options, command)

  docker_command = replace(string(DOCKER(sudo = sudo)), "`" => "")
  "Starting docker container with `$docker_command run $(join(options, " "))`" |> println

  `$(DOCKER(sudo = sudo)) run $options` |> Genie.Deploy.run
end

end # end module Docker

########

module Heroku

import Genie

const HEROKU = @static Sys.iswindows() ? `heroku.cmd` : `heroku`

"""
    apps()

Returns list of apps available on Heroku account.
"""
function apps()
  `$HEROKU apps` |> Genie.Deploy.run
end

"""
    createapp(appname::String; region::String = "us")

Runs the `heroku create` command to create a new app in the indicated region.
See https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-apps-create-app
"""
function createapp(appname::String; region::String = "us")
  `$HEROKU create $(appname) --region $region` |> Genie.Deploy.run
end


"""
    push(appname::String; apptype::String = "web")

Invokes the `heroku container:push` which builds, then pushes Docker images to deploy your Heroku app.
See https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-container-push
"""
function push(appname::String; apptype::String = "web")
  `$HEROKU container:push $apptype -a $appname` |> Genie.Deploy.run
end


"""
    release(appname::String; apptype::String = "web")

Invokes the `keroku container:release` which releases previously pushed Docker images to your Heroku app.
See https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-container-push
"""
function release(appname::String; apptype::String = "web")
  `$HEROKU container:release $apptype -a $appname` |> Genie.Deploy.run
end


"""
    open(appname::String)

Invokes the `heroku open` command which open the app in a web browser.
See https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-apps-open-path
"""
function open(appname::String)
  `$HEROKU open -a $appname` |> Genie.Deploy.run
end


"""
    login()

Invokes the `heroku container:login` to log in to Heroku Container Registry,
See https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-container-login
"""
function login()
  `$HEROKU container:login` |> Genie.Deploy.run
end


"""
    logs(appname::String; lines::Int = 1_000)

Display recent heroku log output.
https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-logs
"""
function logs(appname::String; lines::Int = 1_000)
  `$HEROKU logs --tail -a $appname -n $lines` |> Genie.Deploy.run
end

end # end module Heroku

end # end module Deploy
