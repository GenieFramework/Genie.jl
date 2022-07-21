# Developing Genie Web Services

Starting up ad-hoc web servers at the REPL and writing small scripts to wrap micro-services works great, but production
apps tend to become complex quickly. They also have more stringent requirements, like managing dependencies, compressing
assets, reloading code, logging, environments, or structuring the codebase in a way which promotes efficient workflows
when working in teams.

Genie enables a modular approach towards app building, allowing to add more components as the need arises. You can start
with the web service template (which includes dependencies management, logging, environments, and routing), and grow it
by sequentially adding DB persistence (through the SearchLight ORM), high performance HTML view templates with embedded
Julia (via `Renderer.Html`), caching, authentication, and more.

## Setting up a Genie Web Service project

Genie packs handy generator features and templates which help bootstrapping and setting up various parts of an application.
These are available in the `Genie.Generator` module.
For bootstrapping a new app we need to invoke one of the functions in the `newapp` family:

```julia
julia> using Genie

julia> Genie.Generator.newapp_webservice("MyGenieApp")
```

If you follow the log messages in the REPL you will see that the command will trigger a flurry of actions in order to set up the new project:

- it creates a new folder, `MyGenieApp/`, which will hosts the files of the app and whose name corresponds to the name of the app,
- within the `MyGenieApp/` folder, it creates the files and folders needed by the app,
- changes the active directory to `MyGenieApp/` and creates a new Julia project within it (adding the `Project.toml` file),
- installs all the required dependencies for the new Genie app (using `Pkg` and the standard `Manifest.toml` file), and finally,
- starts the web server

---
**TIP**

Check out the `?help` documentation for `Genie.Generator.newapp`, `Genie.Generator.newapp_webservice`,
`Genie.Generator.newapp_mvc`, and `Genie.Generator.newapp_fullstack` too see what options are available for bootstrapping
applications. We'll go over the different configurations in upcoming sections.

---

## The file structure

Our newly created web service has this file structure:

```julia
├── .gitattributes
├── .gitignore
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── public
├── routes.jl
├── src
└── test
```

These are the roles of each of the files and folders:

- `Manifest.toml` and `Project.toml` are used by Julia and `Pkg` to manage the app's dependencies.
- `bin/` includes scripts for starting up a Genie REPL or a Genie server.
- `bootstrap.jl` and the files within `src/` are used by Genie to load the application and _should not be modified_ unless you know what you're doing.
- `config/` includes the per-environment configuration files.
- `public/` is the document root, which includes static files exposed by the app on the network/internet.
- `routes.jl` is the dedicated file for registering Genie routes.
- the `test/` folder is set up to store the unit and integration tests for the app.
- `.gitattributes` and `.gitignore` are used by Git to manage the project's files.

---
**HEADS UP**

After creating a new app you might need to change the file permissions to allow editing/saving the files such as `routes.jl`.

---

## Adding logic

You can now edit the `routes.jl` file to add some logic, at the bottom of the file:

```julia
route("/hello") do
  "Welcome to Genie!"
end
```

If you now visit <http://127.0.0.1:8000/hello> you'll see a warm greeting.

## Extending the app

Genie apps are just plain Julia projects. This means that `routes.jl` will behave like any other Julia script - you can
reference extra packages, you can switch into `pkg>` mode to manage per project dependencies, include other files, etcetera.

If you have existing Julia code that you want to quickly load into a Genie app, you can add a `lib/` folder in the root
of the app and place your Julia files there. If the folder exists, `lib/` and all its subfolders are automatically loaded
by Genie, recursively.

---
**WARNING**

If you add the `lib/` folder while the Genie app is running, you will need to restart the app to load the files.

---

If you need to add database support, you can always add the SearchLight ORM by running `julia> Genie.Generator.db_support()`
in the app's REPL.

However, if your app grows in complexity and you develop it from scratch, it is more efficient to take advantage of
Genie's resource-oriented MVC structure.
