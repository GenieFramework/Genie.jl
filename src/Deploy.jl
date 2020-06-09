module Deploy

module Docker


import Revise
import Genie, Genie.FileTemplates


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
                    host = "127.0.0.1", port::Int = 8000, dockerport::Int = 80, force::Bool = false,
                    websockets_port::Int = 8001, websockets_dockerport::Int = 8001)
  filename = normpath(joinpath(path, filename))
  isfile(filename) && force && rm(filename)
  isfile(filename) && error("File $(filename) already exists. Use the `force = true` option to overwrite the existing file.")

  open(filename, "w") do io
    write(io, FileTemplates.dockerfile(user = user, env = env, filename = filename, host = host,
                                        port = port, dockerport = dockerport,
                                        websockets_port = websockets_port, websockets_dockerport = websockets_dockerport))
  end

  "Docker file successfully written at $(abspath(filename))" |> println
end


"""
    build(path::String = "."; appname = "genie")

Builds the Docker image based on the `Dockerfile`
"""
function build(path::String = "."; appname::String = "genie")
  `docker build -t "$appname" $path` |> Base.run

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
                mountapp::Bool = false, image::String = "genie", command::String = "bin/server", rm::Bool = true, it::Bool = true,
                websockets_hostport::Int = 8001, websockets_containerport::Int = 8001)
  options = []
  it && push!(options, "-it")
  rm && push!(options, "--rm")
  push!(options, "-p")
  push!(options, "$hostport:$containerport")
  push!(options, "-p")
  push!(options, "$websockets_hostport:$websockets_containerport")
  push!(options, "--name")
  push!(options, "$containername")
  if mountapp
    push!(options, "-v")
    push!(options,  "$(pwd()):$appdir")
  end
  push!(options, image)
  isempty(command) || push!(options, command)

  "Starting docker container with `docker run $(join(options, " "))`" |> println

  `docker run $options` |> Base.run
end

end # end module Docker

########

module Heroku

function createapp(appname::String; region::String = "us")
  `heroku create $(lowercase(appname)) --region $region` |> Base.run
end


function push(appname::String; apptype::String = "web")
  `heroku container:push $apptype -a $appname` |> Base.run
end


function release(appname::String; apptype::String = "web")
  `heroku container:release $apptype -a $appname` |> Base.run
end


function open(appname::String)
  `heroku open -a $appname` |> Base.run
end


function login()
  `heroku container:login` |> Base.run
end


function logs(appname::String; lines::Int = 1_000)
  `heroku logs --tail -a $appname -n $lines` |> Base.run
end

end # end module Heroku

end # end module Deploy
