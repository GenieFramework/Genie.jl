# Developing Genie apps

Starting up ad-hoc web servers at the REPL and building small web services scripts works great, but production apps tend to become complex very quicly. They also have more stringent requirements, like managing dependencies, compressing assets, reloading code, logging, environments, or structuring the codebase in a way which promotes efficient workflows when working in teams.

Genie apps provide all these features, from dependency management and versioning (using Julia's `Pkg` since a Genie app is a Julia project), to a powerful asset pipeline (using industry vetted tools like Yarn and Webpack), automatic code reloading in development (provided by `Revise.jl`), and a clear resource-oriented MVC layout.

Genie enables a modular approach towards app building, allowing to add more components as the need arises. You can start with a basic app (which includes dependencies management, logging, environments, and routing) and grow it by sequentially adding DB persistencen support (through the SearchLight ORM), high performance HTML view templates with embedded Julia (via Flax), asset pipeline and compilation, and more.

## Setting up a Genie micro-framework project

Genie packs handly generator features which help bootstrapping and setting up various parts of an application. For bootstrapping a new app we need to invoke the `newapp` method:

```julia
julia> using Genie

julia> Genie.newapp("MyGenieApp")
```

If you follow the log messages in the REPL you will see that the command will trigger a flurry of actions in order to set up the new project:

- it adds a new folder, `MyGenieApp/`
- within the folder, it creates the files and folders needed by the app
- changes the active directory to `MyGenieApp/` and creates a new Julia project within it
- installs all the required dependencies for the new Genie app
- starts the web server

---
**TIP**

Check out the inline help for `Genie.newapp` too see what options are available for bootstrapping applications.
We'll go over the different configurations in upcoming sections.

---

## The file structure

Our newly created app has the following file structure:

```julia
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── env.jl
├── genie.jl
├── log
├── public
├── routes.jl
└── src
```

These are the roles of each of the files and folders:

- `Manifest.toml` and `Project.toml` are used by Julia and `Pkg` to manage the app's dependencies.
- `bin/` includes scripts for staring up a Genie REPL or a Genie server in the app's context (loading the app).
- `bootstrap.jl`, `genie.jl`, as well as all the files within `src/` are used by Genie to load the application and should not be user modified
- `config/` includes the per-environment configuration files.
- `env.jl` sets up the default environment for the app - can be edited to set the default environment (one of `dev`, `test` or `prod`). The default environment is `dev`.
- `log/` is used by Genie to store per-environment log files.
- `public/` the document root, includes static files exposed by the on the network/internet.
- `routes.jl` dedicated file for registering Genie routes.

---
**HEADS UP**

After creating a new app you might need to change the file permissions to allow editing/saving the files such as `routes.jl`.

---

## Adding logic

You can now edit the `routes.jl` file to add your logic, at the bottom of the file:

```julia
route("/hello") do
  "Welcome to Genie!"
end
```

If you now visit <http://127.0.0.1:8000/hello> you'll see a warm greeting.

## Growing the app

Genie apps are just plain Julia projects. This means that `routes.jl` will behave like any other Julia script - you can reference extra packages, you can switch into `pkg>` mode to manage per project dependencies, include other files, etcetera.

If you have existing Julia code that you want to quickly load into a Genie app, you can add a `lib/` folder in the root of the app and place your Julia files there. When available, `lib/` is automatically added to the `LOAD_PATH` -- including all its subfolders, recursively.

However, if your app grows in complexity and you develop it from scratch, it is more efficient to take advantage of Genie's resource-oriented MVC structure. Follow up to see how to do it in the next sections.
