# Using Genie with Docker

Genie comes with extended support for containerizing apps using Docker. The functionality is provided by the official `GenieDeployDocker` plugin.

## Setting up `GenieDeployDocker`

In order to use the Docker integration features, first we need to add the `GenieDeployDocker` plugin for `Genie`.

```julia
pkg> add GenieDeployDocker
```

## Generating the Genie-optimised `Dockerfile`

You can bootstrap the Docker setup by invoking the `GenieDeployDocker.dockerfile()` function. This will generate a custom `Dockerfile` optimized for Genie web apps containerization. The file will be generated in the current work dir (or where instructed by the optional argument `path` -- see the help for the `dockerfile()` function).

Once generated, you can edit it and customize it as needed - Genie will not overwrite the file, thus preserving any changes (unless you call the `dockerfile` function again, passing the `force=true` argument).

The behaviour of `dockerfile()` can be controlled by passing any of the multiple optional arguments supported.

## Building the Docker container

Once we have our `Dockerfile` ready, we can invoke `GenieDeployDocker.build()` to set up the Docker container. You can pass any of the supported optional arguments to configure settings such as the container's name (by default `"genie"`), the path (defaults to current work dir), and others (see the output of `help?> GenieDeployDocker.dockerfile` for all the available options).

## Running the Genie app within the Docker container

When the image is ready, we can run it with `GenieDeployDocker.run()`. We can configure any of the optional arguments in order to control how the app is run. Check the inline help for the function for more details.

## Examples

First let's create a Genie app:

```julia
julia> using Genie

julia> Genie.Generator.newapp("DockerTest")
[ Info: Done! New app created at /your/app/path/DockerTest
# output truncated
```

When it's ready, let's add the `Dockerfile`:

```julia
julia> using GenieDeployDocker

julia> GenieDeployDocker.dockerfile()
Docker file successfully written at /your/app/path/DockerTest/Dockerfile
```

Now, to build our container:

```julia
julia> GenieDeployDocker.build()
# output truncated
Successfully tagged genie:latest
Docker container successfully built
```

And finally, we can now run our app within the Docker container:

```julia
julia> GenieDeployDocker.run()
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp genie bin/server`
# output truncated
```

We should then see the familiar Genie loading screen, indicating the app's loading progress and notifying us once the app is running.

Our application starts inside the Docker container, binding port 8000 within the container (where the Genie app is running) to the port 80 of the host. So we are now able to access our app at `http://localhost`. If you navigate to `http://localhost` with your favourite browser you'll see Genie's welcome page. Notice that we don't access on port 8000 - this page is served from the Docker container on the default port 80.

## Inspecting the containers

We can get a list of available container by using `GenieDeployDocker.list()`. This will show only the currently running containers
by default, but we can pass the `all=true` argument to also include containers that are offline.

```julia
julia> GenieDeployDocker.list()
CONTAINER ID   IMAGE     COMMAND        CREATED         STATUS         PORTS                          NAMES
c87bfd8322cc   genie     "bin/server"   6 minutes ago   Up 6 minutes   80/tcp, 0.0.0.0:80->8000/tcp   genieapp
Process(`docker ps`, ProcessExited(0))
```

## Stopping running containers

The running containers can be stopped by using the `GenieDeployDocker.stop()` function, passing the name of the container.

```julia
julia> GenieDeployDocker.stop("genieapp")
```

## Using Docker during development

If we want to use Docker to serve the app during development, we need to _mount_ our app from host (your computer) into the container -- so that we can keep editing our files locally, but see the changes reflected in the Docker container. In order to do this we need to pass the `mountapp = true` argument to `GenieDeployDocker.run()`, like this:

```julia
julia> GenieDeployDocker.run(mountapp = true)
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp -v /Users/adrian/DockerTest:/home/genie/app genie bin/server`
```

When the app finishes starting, we can edit the files on the host using our favorite IDE, and see the changes reflected in the Docker container.

## Creating an optimized Genie sysimage with `PackageCompiler.jl`

If we are using Docker containers to deploy Genie apps in production, you can greatly improve the performance of the app by preparing a precompiled sysimage for Julia. We can include this workflow as part of the Docker `build` step as follows.

### Edit the `Dockerfile`

We'll start by making a few changes to our `Dockerfile`, as follows:

1/ Under the line `WORKDIR /home/genie/app` add

```dockerfile
# C compiler for PackageCompiler
RUN apt-get update && apt-get install -y g++
```

2/ Under the line starting with `RUN julia -e` add

```dockerfile
# Compile app
RUN julia --project compiled/make.jl
```

You may also want to replace the line saying

```dockerfile
ENV GENIE_ENV "dev"
```

with

```dockerfile
ENV GENIE_ENV "prod"
```

to configure the application to run in production (first test locally to make sure that everything is properly configured to run the app in production environment).

### Add `PackageCompiler.jl`

We also need to add `PackageCompiler` as a dependency of our app:

```julia
pkg> add PackageCompiler
```

### Add the needed files

Create a new folder to host our files:

```julia
julia> mkdir("compiled")
```

Now create the following files:

```julia
julia> touch("compiled/make.jl")
julia> touch("compiled/packages.jl")
```

### Edit the files

Now to put the content into each of the files.

#### Preparing the `packages.jl` file

Here we simply put an array of package that our app uses and that we want to precompile, ex:

```julia
# packages.jl
const PACKAGES = [
  "Dates",
  "Genie",
  "Inflector",
  "Logging"
]
```

#### Preparing the `make.jl` file

Now edit the `make.jl` file as follows:

```julia
# make.jl
using PackageCompiler

include("packages.jl")

PackageCompiler.create_sysimage(
  PACKAGES,
  sysimage_path = "compiled/sysimg.so",
  cpu_target = PackageCompiler.default_app_cpu_target()
)
```

#### Using the precompiled image

The result of these changes is that `PackageCompiler` will create a new Julia sysimage that will be stored inside the `compiled/sysimg.so` file. The last step is to instruct our `bin/server` script to use the image.

Edit the `bin/server` file and make it look like this:

```bash
julia --color=yes --depwarn=no --project=@. --sysimage=compiled/sysimg.so -q -i -- $(dirname $0)/../bootstrap.jl -s=true "$@"
```

With this change we're passing the additional `--sysimage` flag, indicating our new Julia sys image.