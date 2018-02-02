# Web Development with Genie

* About Genie
* Requirements
* MVC structure
* Example app - 1. Hello World
* Interacting with Genie
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
  * Validators
  * Migrations
  * Database seeding
* File structure of a Genie app
  * /app
  * /lib - Integrating with existing Julia code
* The frontend stack: Webpack and Yarn
* Genie Channels (WebSockets communication)
* Caching
  * File system
  * Memcache 
* Sessions
* Authentication
* Logging
* Tasks / Utilities
* Environments and configuration
* Hosting Genie apps

## About Genie
Genie is a web framework for developing professional grade websites and applications. It is written in Julia and provides a complete toolbox for creating powerful web applications and web APIs. Genie's phisolophy is heavily influenced by Ruby on Rails - it tries to make things as simple, productive and enjoyable as possible (but no more). At the same time, if focuses on high performance, leveraging Julia's native speed.

## Requirements
Genie requires at least Julia v0.6.
In order to get Genie, you need to clone it:
`Pkg.clone("https://github.com/essenciary/Gennie.jl")`

## Genie's MVC structure
Genie builds on Julia's high performance and friendly syntax while providing a rich set of high level libraries for developing web products in a highly productive environment. Genie apps implement the Model-View-Controller (MVC) design pattern, used by many web frameworks, including Ruby on Rails, Django and Laravel. This separation of concerns combined with the convention-over-configuration approach creats a clear and efficient web development workflow.

In traditional MVC style, when a client makes a request to a Genie app, the Genie web server (`HttpServer.jl`) which is listening on the port accepts the request and sets it up to be handled by the `Router`. The `Router` analyzes the structure of the request URL and invokes the code defined for handling the request. For complex logic, this code should stay within a function in a dedicated `Controller` module. For simple scenarios, the code for generating the response can be defined inline, in the `route` itself.

Once invoked from the `Router`, the `Controller` orchestrates the interactions between the `Model` layer, which accesses the database, and the `View` layer, which renders a response as HTML, JSON or other supported format. The executed `Controller` function (called `action` in MVC parlance) needs to return a `HttpResponse` object -- or another object that can automatically converted by Genie (like a `String`). Genie provides a multitude of helper functions for generating the `Response` objects -- so that the developers can focus on the logic of their apps instead of handling lower level communication.

## Example app 1: Hello World
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

## Interacting with Genie
Once you have created your Genie app, there are two main ways to interact with it.
1. by starting an interactive Genie REPL:
```
$> bin/repl
```
This command will start a Julia REPL, load the Genie environment and the app's configuration and provide you a `genie>` prompt. From here you can access all the modules of the app, including to manually start the web server:
```
genie> AppServer.startup()
```

2. by starting the web server
```
$> bin/server
```
This will load the app and automatically start the server on the configured port (by default, 8000). This command will not provide an interactive prompt.

## Generators
Genie is built upon the "convention over configuration" principle. This makes things a lot more simpler by removing the mental burdain or having to decide where to place and how to name each component of an app. As long as the various modules and files are placed in their right folder and named as expected, Genie will automagically fit everything together.

However, us, developers, are not really famous for our memory -- and many conventions can quickly become cumbersome. Computers are much better at remembering things - and they'll happily do repetitive tasks without a hint of boredome. Thus, Genie comes with a multitude of generators, which assist with setting up the various components of the app.

The generators are accessible from both the command line and within the Genie REPL. You can get the list of available options with:
```
$> bin/repl --help

Genie web framework CLI

positional arguments:
  s                     starts HTTP server

optional arguments:
  --server:start SERVER:START
                        starts HTTP server
  -p, --server:port SERVER:PORT
                        HTTP server port (default: "8000")
  -w, --server:workers SERVER:WORKERS
                        Number of workers used by the app -- use any
                        value greater than 1 to overwrite the config
                        (default: "1")
  --websocket:start WEBSOCKET:START
                        starts web sockets server
  --websocket:port WEBSOCKET:PORT
                        web sockets server port (default: "8008")
  --app:new APP:NEW     app_name -> creates a new Genie app
  --db:init DB:INIT     true -> create database and core tables
                        (default: "false")
  --model:new MODEL:NEW
                        model_name -> creates a new model, ex: Product
  --controller:new CONTROLLER:NEW
                        controller_name -> creates a new controller,
                        ex: Products
  --channel:new CHANNEL:NEW
                        channel_name -> creates a new channel, ex:
                        Products
  --resource:new RESOURCE:NEW
                        resource_name -> creates a new resource folder
                        with all its files, ex: products
  --migration:status MIGRATION:STATUS
                        true -> list migrations and their status
                        (default: "false")
  --migration:list MIGRATION:LIST
                        alias for migration:status (default: "false")
  --migration:new MIGRATION:NEW
                        migration_name -> create a new migration, ex:
                        create_table_foos
  --migration:up MIGRATION:UP
                        true -> run last migration up
                        migration_module_name -> run migration up, ex:
                        CreateTableFoos
  --migration:allup MIGRATION:ALLUP
                        true -> run up all down migrations (default:
                        "false")
  --migration:down MIGRATION:DOWN
                        true -> run last migration down
                        migration_module_name -> run migration down,
                        ex: CreateTableFoos
  --migration:alldown MIGRATION:ALLDOWN
                        true -> run down all up migrations (default:
                        "false")
  --task:list TASK:LIST
                        true -> list tasks (default: "false")
  --task:new TASK:NEW   task_name -> create a new task, ex: SyncFiles
  --task:run TASK:RUN   task_name -> run task
  --test:run TEST:RUN   true -> run tests (default: "false")
  --version             show version information and exit
  -h, --help            show this help message and exit

Visit http://genieframework.com for more info
```

You can see in the above list all the available options -- most of them being generators. Genie exposes handy scripts for creating new models, controllers, channels, migrations and tasks. It also provides a few utilities for managing migrations, the web server, web sockets server and others.

One of the most useful generators is the new resource. It will create a full resources - that is, all the files associated with exposing a business entity within a Genie app. A resource can be a `page` or a `user` or a `product`. The resource generator will create the model, controller, views, validator and channel files.

It can be run as follows:
```
$> bin/repl --resource:new=Product
```
Running this will output some useful log info, to let you know about the progress. Once done you'll find a new folder, `products` under `app/resources`. The `products` folder will include all necessary files for exposing a product entity in Genie's MVC stack.

## The Router
Genie's `Router` is a key component in the MVC stack. Its main job is to process the URL of the request and invoke the corresponding `Module` and `Function`, as designated for handling the request. Its also in charge of extracting the various request parameters (`GET` and `POST` variables and URL components) and making them available in the controller.

The routes, that is, the mappings between URI structures and Modules and Functions, are defined in the `config/routes.jl` file.

A `route` is defined as a call to the `route(...)` function. The `route(...)` function accepts parameters in three ways:

#### 1. Anonymous function
```julia
route("/products/:id/buy") do
  # code to handle the request here
end
```
In this case, a URL of the form `/products/42/buy` will match -- and the corresponding anonymous function will be invoked.

#### 2. Via keyword arguments
```julia
route("/products/:id/show", resource = :products, controller = :ProductsController, :action = :show)
```
Similarely, a URL of the form `/products/5/show` will be matched to the `ProductsController.show()` function withing the `products` folder (resource) -- invoking the `show()` function.

#### 3. Via destination "hash"
The mapping for a route can also be provided as a special string, or hash, represented again by the concatenation of the resource name, controller name and action.
```julia
route("/products/:id/return", "products#ProductsController.return")
```
Unsurprisingly, a link like `products/38/return` will cause Genie to invoke `ProductsController.return()` within the `products` resource (folder).

### Additional `route` arguments
All three of the above `route(...)` methods accept a few keyword arguments.
* `method = GET` - by default the routes match `GET` requests. But routes can be defined for other types of requests. The other available methods are: `POST`, `PUT`, `PATCH` and `DELETE`.
* `named::Symbol = :__anonymous_route` - all routes are named so that they can be referenced, for example by the link helper, to dynamically build links to URLs defined by routes. The `named` parameter can be optionally provided -- if it is not provided Genie will generate a unique route name based on the route's destination.
* `with::Dict = Dict{Symbol,Any}()` - this is a container where you can optionally define extra route parameters that will be passed into your controller.

### Type constrains for the route params
In the previous examples, a URL structure like `/products/:id/return` will match both `/products/23/return` and `/products/dish-washer/return`. Most of the times that's not what you want. That's why Genie allows us to constrain the type of a URI param by simply adding the standard Julia type annotation, for example `:id::Int`, as in `/products/:id::Int/return`. This route will no longer match `/products/dish-washer/return`. For that you either have to define a `/products/:id::String/return` or leave it unannotated (which would correspond to `:id::Any`).

Routes are matched from top to bottom -- and once a route is matched, the corresponding destination is invoked without further checking for better / stricter match. For this reason you should put the most specific routes at the top, with more generic ones at the bottom.