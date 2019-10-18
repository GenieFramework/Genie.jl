# Using Genie with Docker

Genie comes with built-in support for containerizing apps. The functionality is available in the `Genie.Deploy.Docker` module.

## Generating the Genie-optimised `Dockerfile`

You can bootstrap the Docker setup by invoking the `Genie.Deploy.Docker.dockerfile()` function. This will generate a custom `Dockerfile` optimized for Genie web apps containerization. The file will be generated in the current work dir (or where instructed by the optional argument `path` -- see the help for the `dockerfile()` function). Once generated, you can edit it and customize it as needed - Genie will not overwrite the file, thus preserving any changes.

The behaviour of `dockerfile()` can be controlled by passing any of the multiple optional arguments supported.

## Building the Docker container

Once we have our `Dockerfile` ready, we can invoke `Genie.Deploy.Docker.build()` in order to build the Docker container. You can optionally pass the container's name (by default `"genie"`) and the path (defaults to current work dir).

## Running the Genie app within the Docker container

When the image is ready, we can run it with `Genie.Deploy.Docker.run()`. We can configure any of the optional arguments in order to control how the app is run. Check the inline help for the function for more details.

## Examples

First let's create a Genie app:

```julia
julia> using Genie

julia> Genie.newapp("DockerTest")
[ Info: Done! New app created at /Users/adrian/DockerTest
# output truncated
```

When it's ready, let's add the `Dockerfile`:

```julia
julia> using Genie.Deploy

julia> Deploy.Docker.dockerfile()
Docker file successfully written at /Users/adrian/DockerTest/Dockerfile
```

Now, to build our container:

```julia
julia> Deploy.Docker.build()
Sending build context to Docker daemon  1.056MB
Step 1/18 : FROM julia:latest
 ---> f4c9686d85da
# output truncated
Successfully tagged genie:latest
Docker container successfully built
```

And finally, we can now run our app within the Docker container:

```julia
julia> Deploy.Docker.run()
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp genie bin/server`

 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

| Web: https://genieframework.com
| GitHub: https://github.com/genieframework/Genie.jl
| Docs: https://genieframework.github.io/Genie.jl
| Gitter: https://gitter.im/essenciary/Genie.jl
| Twitter: https://twitter.com/GenieMVC

Genie v0.19.0
Active env: DEV

Web Server starting at http://0.0.0.0:8000
```

Our application starts inside the Docker container, binding port 8000 within the container (where the Genie app is running) to the port 80 of the host. So we are now able to access our app at `http://localhost`. If you navigate to `http://localhost` with your favourite browser you'll see Genie's welcome page. Notice that we don't access on port 8000 - this page is served from the Docker container on the default port 80.

### Using Docker during development

If we want to use Docker to serve the app during development, we need to _mount_ our app from host (your computer) into the container -- so that we can keep editing our files locally, but see the changes reflected in the Docker container. In order to do this we need to pass the `mountapp = true` argument to `Deploy.Docker.run()`, like this:

```julia
julia> Deploy.Docker.run(mountapp = true)
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp -v /Users/adrian/DockerTest:/home/genie/app genie bin/server`
```

When the app finishes starting, we can edit the files on the host using our favourite IDE, and see the changes reflected in the Docker container.
