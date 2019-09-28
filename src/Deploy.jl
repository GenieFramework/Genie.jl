module Deploy

module Docker

using Genie, Genie.FileTemplates

function dockerfile(path::String = "."; user::String = "genie", env::String = "dev",
                    filename::String = "Dockerfile", port::Int = 8000, dockerport::Int = 80, force::Bool = false)
  filename = normpath(joinpath(path, filename))
  isfile(filename) && force && rm(filename)
  isfile(filename) && error("File $(filename) already exists. Use the `force = true` option to overwrite the existing file.")

  open(filename, "w") do io
    write(io, FileTemplates.dockerfile(user = user, env = env, filename = filename,
                                        port = port, dockerport = dockerport))
  end

  "Docker file successfully written at $(abspath(filename))" |> println
end


function build(path::String = "."; appname = "genie")
  `docker build -t "$appname" $path` |> Base.run

  "Docker container successfully built" |> println
end


function run(; containername::String = "genieapp", hostport::Int = 80, containerport::Int = 8000, appdir::String = "/home/genie/app",
                mountapp::Bool = false, image::String = "genie", command::String = "bin/server", rm::Bool = true, it::Bool = true)
  options = []
  it && push!(options, "-it")
  rm && push!(options, "--rm")
  push!(options, "-p")
  push!(options, "$hostport:$containerport")
  push!(options, "--name")
  push!(options, "$containername")
  if mountapp
    push!(options, "-v")
    push!(options,  "$(pwd()):$appdir")
  end
  push!(options, image)
  isempty(command) || push!(options, command)

  "Starting docker container with `docker run $options`" |> println

  `docker run $options` |> Base.run
end

end # end module Docker

########

module Heroku

function createapp(appname::String; appendrand::Bool = false)
  `heroku create $appname` |> Base.run
end


function push(appname::String)
  `heroku container:push web -a $appname` |> Base.run
end


function release(appname::String)
  `heroku container:release web -a $appname` |> Base.run
end


function open(appname::String)
  `heroku open -a $appname` |> Base.run
end


function login()
  `heroku container:login` |> Base.run
end

end # end module Heroku

end # end module Deploy