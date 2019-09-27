module Deploy

module Docker

using Genie, Genie.FileTemplates

function dockerfile(path::String = "."; user::String = "genie", supervisor::Bool = false, nginx::Bool = false,
                    env::String = "dev", filename::String = "Dockerfile", port::Int = 8000, dockerport::Int = 80, force::Bool = false)
  filename = normpath(joinpath(path, filename))
  isfile(filename) && force && rm(filename)
  isfile(filename) && error("File $(filename) already exists. Use the `force = true` option to overwrite the existing file.")

  open(filename, "w") do io
    write(io, FileTemplates.dockerfile(user = user, supervisor = supervisor, nginx = nginx, env = env, filename = filename,
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

  `docker run $options` |> Base.run
end


function supervisord(path::String = "."; user::String = "genie", env::String = "dev", filename::String = "supervisord.conf", force::Bool = false)
  filename = normpath(joinpath(path, filename))
  isfile(filename) && force && rm(filename)
  isfile(filename) && error("File $(filename) already exists. Use the `force = true` option to overwrite the existing file.")

  open(filename, "w") do io
    write(io, FileTemplates.supervisordconf(user = user, env = env))
  end

  "supervisord.conf file successfully written at $(abspath(filename))" |> println
end

end # end module Docker

end # end module Deploy