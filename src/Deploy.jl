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
end


function run(; containername::String = "genieapp", hostport::Int = 80, containerport::Int = 8000,
                mountapp::Bool = false, image::String = "genie", command::String = "", rm::Bool = true, it::Bool = true)
  `docker run $(it ? "-it" : "") $(rm ? "--rm" : "") -p $hostport:$containerport --name geniedev -v $(mountapp && "\"$PWD\":/app") $image $command` |> Base.run
end

end # end module Docker

end # end module Deploy