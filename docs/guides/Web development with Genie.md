#Web Development with Genie

* About Genie
* Requirements
* MVC structure
* Example app - Hello World
* Generators
* Router
* Controller
  * @params collection
* View (Flax.jl)
  * @vars collection
  * Rendering
    * Views
      * HTML
      * Markdown
      * JSON
    * Layouts
* Helpers
* Model (SearchLight.jl)
* Migrations
* Database seeding
* File structure of a Genie app
  * /app
  * /lib - Integrating with existing Julia code
* The frontend stack: Webpack and Yarn
* Genie Channels (WebSockets communication)
* Caching
* Sessions
* Authentication
* Logging
* Tasks / Utilities
* Environments and configuration
* Hosting Genie apps

##About Genie
Genie is a web framework for developing professional grade websites and applications. It is written in Julia and provides a complete toolbox for creating powerful web applications and web APIs. Genie's phisolophy is heavily influenced by Ruby on Rails - it tries to make things as simple, productive and enjoyable as possible (but no more). At the same time, if focuses on high performance, leveraging Julia's native speed.

##Requirements
Genie requires at least Julia v0.6.
In order to get Genie, you need to clone it:
`Pkg.clone("https://github.com/essenciary/Gennie.jl")`

##Genie's MVC structure
Genie builds on Julia's high performance and friendly syntax while providing a rich set of high level libraries for developing web products in a highly productive environment. Genie apps implement the Model-View-Controller (MVC) design pattern, used by many web frameworks, including Ruby on Rails, Django and Laravel. This separation of concerns combined with the convention-over-configuration approach creats a clear and efficient web development workflow.

In traditional MVC style, when a client makes a request to a Genie app, the Genie web server (`HttpServer.jl`) which is listening on the port accepts the request and sets it up to be handled by the `Router`. The `Router` analyzes the structure of the request URL and invokes the code defined for handling the request. For complex logic, this code should stay within a function in a dedicated `Controller` module. For simple scenarios, the code for generating the response can be defined inline, in the `route` itself.

Once invoked from the `Router`, the `Controller` orchestrates the interactions between the `Model` layer, which accesses the database, and the `View` layer, which renders a response as HTML, JSON or other supported format. The executed `Controller` function (called `action` in MVC parlance) needs to return a `HttpResponse` object -- or another object that can automatically converted by Genie (like a `String`). Genie provides a multitude of helper functions for generating the `Response` objects -- so that the developers can focus on the logic of their apps instead of handling lower level communication.

##Example app 1: Hello World
Let's take an example -- a very simple "Hello world" web app. Open a Julia REPL to create our app. Let Julia know that we'll be needing the `Genie` package.
```julia
using Genie
```
Genie provides a series of generators that make setting things up simpler, avoiding the need to write boilerplate code. One such generator sets up a new app. It will automatically create the app's folder and will create the needed files -- just make sure you're in the right folder before generating the app. If you need to, you can swtich the REPL into `shell>` mode and `cd` or use Julia's own `cd(...)` function.
```julia
Genie.REPL.new_app("hello-world")
```
Genie will promptly generate the file structure for the new `hello-world` and will install non-METADATA dependencies.
```
2017-12-14T19:20:09.458 - info: Done! New app created at /your/path/here/hello-world
2017-12-14T19:20:09.708 - info: Looking for dependencies
2017-12-14T19:20:09.708 - info: Checking for Flax rendering engine support
2017-12-14T19:20:09.708 - info: Finished adding dependencies
2017-12-14T19:20:09.708 - info: Starting your brand new Genie app - hang tight!
```
Once ready, it will load the new app and take you to its REPL:
```
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

Starting Genie in >> DEV << mode using 1 worker(s)
genie>
```
The default Genie app structure, at its first level, looks like this:
```
├── LICENSE.md
├── README.md
├── REQUIRE
├── app
├── bin
├── cache
├── config
├── db
├── docs
├── env.jl
├── genie.jl
├── lib
├── log
├── package.json
├── public
├── session
├── task
├── test
└── webpack.config.js
```
We need to add a route to handle requests to our app and send our warm "Hello World" message to the clients. The routes configuration can be found in `config/routes.jl`.
```
./config
├── app.jl
├── database.yml
├── env
├── initializers
├── loggers.jl
├── plugins.jl
├── routes.jl
└── secrets.jl
```
Open the `config/routes.jl` file in your favorite Julia editor.