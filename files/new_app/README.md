![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie

## The highly productive Julia web framework

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.

### Current status

Genie is compatible with Julia v1.0 and up.

# Getting started

## Installing Genie

In a Julia session switch to `pkg>` mode to add `Genie`:

```julia
julia>] # switch to pkg> mode
pkg> add https://github.com/essenciary/Genie.jl
```

Alternatively, you can achieve the above using the `Pkg` API:

```julia
julia> using Pkg
julia> pkg"add https://github.com/essenciary/Genie.jl"
```

When finished, make sure that you're back to the Julian prompt (`julia>`)
and bring `Genie` into scope:

```julia
julia> using Genie
```

## Using Genie in an interactive environment (Jupyter/IJulia, REPL, etc)

Genie can be used for ad-hoc exploratory programming, to quickly whip up a web server
and expose your Julia functions.

Once you have `Genie` into scope, you can define a new `route`.
A `route` maps a URL to a function.

```julia
julia> import Genie.Router: route
julia> route("/") do
         "Hi there!"
       end
```

You can now start the web server using

```julia
julia> Genie.AppServer.startup()
```

Finally, now navigate to <http://localhost:8000> – you should see the message "Hi there!".

We can define more complex URIs which can also map to previously defined functions:

```julia
julia> function hello_world()
         "Hello World!"
       end
julia> route("/hello/world", hello_world)
```

Obviously, the functions can be defined anywhere (in any other module) as long as they are accessible in the current scope.

You can now visit <http://localhost:8000/hello/world> in the browser.

Of course we can access GET params:

```julia
julia> import Genie.Router: @params
julia> route("/echo/:message") do
         @params(:message)
       end
```

Accessing <http://localhost:8000/echo/ciao> should echo "ciao".

And we can even match by their types:

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y)
       end
```

By default, GET params are extracted as `SubString` (more exactly, `SubString{String}`).
If type constraints are added, Genie will attempt to convert the `SubString` to the indicated type.

For the above to work, we also need to tell Genie how to perform the conversion:

```julia
julia> import Base.convert
julia> convert(::Type{Int}, s::SubString{String}) = parse(Int, s)
```

Now if we access <http://localhost:8000/sum/2/3> we should see `5`

### Handling query string params

Query string params, which look like `...?foo=bar&baz=2` are automatically unpacked by Genie and placed into the `@params` collection. For example:

```julia
julia> route("/sum/:x::Int/:y::Int") do
         @params(:x) + @params(:y) + parse(Int, get(@params, :initial_value, "0"))
       end
```

Accessing <http://localhost:8000/sum/2/3?initial_value=10> will now output `15`.

---

## Developing a simple API backend

Genie makes it very easy to quickly set up a REST API backend. All it takes is a few lines of code:

```julia
using Genie
import Genie.Router: route
import Genie.Renderer: json!

Genie.config.run_as_server = true

route("/") do
  (:message => "Hi there!") |> json!
end

Genie.AppServer.startup()
```

The key bit here is `Genie.config.run_as_server = true`. This will start the server synchronously so the `startup()` function won't return. This endpoint can be run directly from the command line - if say, you save the code in a `rest.jl` file:

```shell
$ julia rest.jl
```

### Accepting JSON payloads

One common requirement when exposing APIs is to accept POST payloads. That is, requests over POST, with a request body, usually as a JSON encoded object. We can build an echo service like this:

```julia
using Genie, Genie.Router, Genie.Renderer, Genie.Requests
using HTTP

route("/echo", method = POST) do
  message = jsonpayload()
  (:echo => (message["message"] * " ") ^ message["repeat"]) |> json!
end

route("/send") do
  response = HTTP.request("POST", "http://localhost:8000/echo", [("Content-Type", "application/json")], """{"message":"hello", "repeat":3}""")

  response.body |> String |> json!
end

Genie.AppServer.startup(async = false)
```

Here we define two routes, `/send` and `/echo`. The `send` route makes a `HTTP` request over `POST` to `/echo`, sending a JSON payload with two values, `message` and `repeat`. In the `/echo` route, we grab the JSON payload using the `Requests.payload()` function, extract the values from the JSON object, and output the `message` value repeated for a number of times equal to the `repeat` value.

If you run the code, the output should be

```javascript
{
  echo: "hello hello hello "
}
```

If the payload contains invalid JSON, the jsonpayload will be set to `nothing`. You can still access the raw payload by using the `Requests.rawpayload()` function. You can also use `rawpayload` if for example the type of request/payload is not JSON.

---

## Working with Genie apps (projects)

Working with Genie in an interactive environment can be useful – but usually we want to persist our application and reload it between sessions. One way to achieve that is to save it as an IJulia notebook and rerun the cells. However, you can get the most of Genie by working with Genie apps. A Genie app is an MVC web application which promotes the convention-over-configuration principle. Which means that by working with a few predefined files, within the Genie app structure, Genie can lift a lot of weight and massively improve development productivity. This includes automatic module loading and reloading, dedicated configuration files, logging, environments, code generators, and more.

In order to create a new app, run:

```julia
julia> Genie.newapp("MyGenieApp")
```

Genie will

* make a new dir called `MyGenieApp` and `cd()` into it,
* create the app as a Julia project,
* activate the project,
* install all the dependencies,
* automatically load the new app environment into the REPL,
* and start the web server on the default port (8000)

At this point you can confirm that everything worked as expected by visiting <http://localhost:8000> in your favourite web browser. You should see Genie's welcome page.

Next, let's add a new route. This time we need to append it to the dedicated `routes.jl` file. Edit `/path/to/MyGenieApp/config/routes.jl` in your favourite editor or run the next snippet (making sure you are in the app's directory):

```julia
julia> edit("config/routes.jl")
```

Append this at the bottom of the `routes.jl` file and save it:

```julia
# config/routes.jl
route("/hello") do
  "Welcome to Genie!"
end
```

Visit <http://localhost:8000/hello> for a warm welcome!

### Loading an app

At any time, you can load and serve an existing Genie app. Genie apps are both Julia projects and Julia modules - the name of the app's module being the name of the app itself, so in our case, `MyGenieApp`. Loading a Genie app will bring into scope all your app's files, including the main app module, controllers, models, etcetera.

Beware that Genie will do its best to generate module names according to Julia's naming conventions, so in PascalCase. This means that even if you name your app say "my_genie_app", the resulting app module will still be `MyGenieApp`.

#### Julia's REPL

First, make sure that you're in the root dir of the app, `MyGenieApp`. This is the project's folder and you can tell by the fact that there should be a `bootstrap.jl` file, plus Julia's `Project.toml` and `Manifest.toml` files, amongst others.

Then run

```julia
julia> using Genie
julia> Genie.loadapp()
```

The app's environment will now be loaded.

In order to start the web server execute

```julia
julia> MyGenieApp.startup()
```

#### MacOS / Linux

You can start an interactive REPL in your app's environment by executing `bin/repl` in the os shell, again while in the project's folder, `MyGenieApp/`.

```shell
$ bin/repl
```

The app's environment will now be loaded.

In order to start the web server execute

```julia
julia> MyGenieApp.startup()
```

If, instead, if you want to directly start the server, use

```shell
$ bin/server
```

#### Windows

On Windows it's similar to macOS and Linux, but dedicated Windows scripts, `repl.bat` and `server.bat` are provided inside the project folder, within the `bin/` folder (so for our example, `MyGenieApp/bin/`).
Double click them or execute them in the os shell to start an interactive REPL session or a server session, respectively.

#### Juno / Jupyter / other Julia environment

First, make sure that you `cd` into your app's project folder. Then:

```julia
using Genie
Genie.loadapp()
```

## Adding your Julia libraries to a Genie app

If you have an existing Julia application or standalone codebase which you'd like to expose over the web through your Genie app, the easiest thing to do is to drop the files into the `lib/` folder. The `lib/` folder is automatically added by Genie to the `LOAD_PATH`.

You can also add folders under `lib/`, they will be recursively added to `LOAD_PATH`. Beware though that this only happens when the Genie app is initially loaded. Hence, an app restart might be required if you add nested folders once the app is loaded.

Once you module is added to `lib/` it will become available in your app's environment. For example, say we have a file `lib/MyLib.jl`:

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

Then we can reference it in `config/routes.jl` as follows:

```julia
# config/routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```

## Working with resources

Adding your code to the `routes.jl` file or placing it into the `lib/` folder works great for small projects, where you want to quickly publish some features on the web. But for any larger projects, we're better off using Genie's MVC structure. By employing the Module-View-Controller design pattern we can break our code in modules with clear responsabilities. Modular code is easier to write, test and maintain.

---

### Check the code

The code for the example app being built in the upcoming paragraphs can be accessed at: <https://github.com/essenciary/Genie-Searchlight-example-app>

---

A Genie app is structured around the concept of "resources". A resource represents a business entity (something like a user, or a product, or an account) and maps to a bundle of files (controller, model, views, etc).

Resources live under the `app/resources/` folder. For example, if we have a web app about "books", a "books/" folder would be placed in `app/resources/` and would contain all the files for publishing books on the web.

### Using Controllers

Controllers are used to orchestrate interactions between client requests, models (handle DB access), and views (responsible with response rendering for the clients). In a standard workflow a `route` points to a method in the controller – which is charged with building and sending the response over the wire.

Let's add a "books" controller. We could do it by hand – but Genie comes with handy generators which will happily do the boring work for us.

#### Generate the Controller

Let's generate our `BooksController`:

```julia
julia> MyGenieApp.newcontroller("Books")
[info]: New controller created at app/resources/books/BooksController.jl
```

Great! Let's edit `BooksController.jl` and add something to it. For example, a function which returns some of Bill Gates' recommended books would be nice. Make sure that `BooksController.jl` looks like this:

```julia
# app/resources/books/BooksController.jl
module BooksController

struct Book
  title::String
  author::String
end

const BillGatesBooks = Book[
  Book("The Best We Could Do", "Thi Bui"),
  Book("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
  Book("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
  Book("The Sympathizer", "Viet Thanh Nguyen"),
  Book("Energy and Civilization, A History", "Vaclav Smil")
]

function billgatesbooks()
  response = "
    <h1>Bill Gates' list of recommended books</h1>
    <ul>
      $( mapreduce(b -> "<li>$(b.title) by $(b.author)", *, BillGatesBooks) )
    </ul>
  "
end

end
```

That should be clear enough – just a plain Julia module.

##### Checkpoint

Before exposing it on the web, we can test it in the REPL:

```julia
julia> BooksController.billgatesbooks()
```

Make sure it works as expected.

##### Setup the route

Now, let's expose our `billgatesbooks` method on the web. We need to add a new route which points to it:

```julia
# config/routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```

That's all! If you now visit `http://localhost:8000/bgbooks` you'll see Bill Gates' list of recommended books.

### Adding views

However, putting HTML into the controllers is a bad idea: that should stay in the view files. Let's refactor our code to use views.

The views used for rendering a resource should be placed inside a "views/" folder, within that resource's own folder. So in our case, we will add an `app/resources/books/views/` folder. Just go ahead and do it, Genie does not provide a generator for this simple task.

#### Naming views

Usually each controller method will have its own rendering logic – hence, its own view file. Thus, it's a good practice to name the view files just like the methods, so we can keep track of where they're used.

At the moment, Genie supports HTML and Markdown view files. Their type is identified by file extension so that's an important part. The HTML views use a ".jl.html" extension while the Markdown files go with ".jl.md".

#### HTML views

All right then, let's add our first view file for the `BooksController.billgatesbooks` method. Let's add an HTML view. With Julia:

```julia
julia> touch("app/resources/books/views/billgatesbooks.jl.html")
```

Genie supports a special type of HTML view, where we can embed Julia code. These are high performance compiled views. They are _not_ parsed as strings: instead, **the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file (in fact, a module)**. Hence, the first time you load a view or after you change one, you might notice a certain delay – it's the time needed to generate and compile the view. On next runs (especially in production) it's blazing fast!

Now all we need to do is to move the HTML code out of the controller and into the view:

```html
<!-- billgatesbooks.jl.html -->
<h1>Bill Gates' top $( length(@vars(:books)) ) recommended books</h1>
<ul>
   <%
      @foreach(@vars(:books)) do book
         "<li>$(book.title) by $(book.author)"
      end
   %>
</ul>
```

As you can see, it's just plain HTML with embedded Julia. We can add Julia code by using the `<% ... %>` code block tags – these should be used for more complex, multiline expressions. Or by plain string interpolation with `$(...)` – for simple values outputting.

It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, your Julia view code _must return a string_ as the result, so that the output of your computation comes up on the page.

Genie provides a series of helpers, like the above used `@foreach` macro.

Also, very important, please notice the `@vars` macro. This is used to access variables which are passed from the controller into the view. We'll see how to do this right now.

#### Rendering views

We now need to refactor our controller to use the view, passing in the expected variables. We will use the `html!` method which renders and outputs the response as HTML (you've seen its `json!` counterpart earlier). Update the definition of the `billgatesbooks` function to be as follows:

```julia
# BooksController.jl
function billgatesbooks()
  html!(:books, :billgatesbooks, books = BillGatesBooks)
end
```

We also need to add `Genie.Renderer` as a dependency, to get access to the `html!` method. So add this at the top of the `BooksController` module:

```julia
using Genie.Renderer
```

The `html!` function takes as its arguments:

* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file)
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out
* and finally, we pass the values we want to expose in the view, as keyword arguments. In this scenario, the `books` keyword argument – which will be available in the view file under `@vars(:books)`.

That's it – our refactored app should be ready!

#### Markdown views

Markdown views work similar to HTML views – employing the same embedded Julia functionality. Here is how you can add a Markdown view for our `billgatesbooks` function.

First, create the corresponding view file, using the `.jl.md` extension. Maybe with:

```julia
julia> touch("app/resources/books/views/billgatesbooks.jl.md")
```

Now edit the file and make sure it looks like this:

```md
<!-- app/resources/books/views/billgatesbooks.jl.md -->
# Bill Gates' $( length(@vars(:books)) ) recommended books
$(
   @foreach(@vars(:books)) do book
      "* $(book.title) by $(book.author)"
   end
)
```

Notice that Markdown views do not support Genie's embedded Julia tags `<% ... %>`. Only string interpolation `$(...)` is accepted and it works across multiple lines.

If you reload the page now, however, Genie will still load the HTML view. The reason is that, _if we have only one view file_, Genie will manage. But if there's more than one, the framework won't know which one to pick. It won't error out but will pick the preferred one, which is the HTML version.

It's a simple change in the `BookiesController`: we have to explicitly tell Genie which file to load, extension and all:

```julia
# BooksController.jl
function billgatesbooks()
  html!(:books, Symbol("billgatesbooks.jl.md"), books = BillGatesBooks)
end
```

**Please keep in mind that Markdown files are not compiled, nor cached, so the performance _will_ be _negatively_ affected.**

Here is the `@time` output for rendering the HTML view:

```julia
[info]: Including app/resources/books/views/billgatesbooks.jl.html
  0.000405 seconds (838 allocations: 53.828 KiB)
```

And here is the `@time` output for the Markdown view:

```julia
[info]: Including app/resources/books/views/billgatesbooks.jl.md
  0.214844 seconds (281.36 k allocations: 13.841 MiB)
```

#### Taking advantage of layouts

Genie's views are rendered within a layout file. Layouts are meant to render the theme of the website, or the "frame" around the view – the elements which are common on all the pages. It can include visible elements, like the main menu or the footer. But also maybe the `<head>` tag or the assets tags (`<link>` and `<script>` tags for loading CSS and JavaScript files in all the pages).

Every Genie app has a main layout file which is used by default – it can be found in `app/layouts/` and is called `app.jl.html`. It looks like this:

```html
<!-- app/layouts/app.jl.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Genie :: The highly productive Julia web framework</title>
    <!-- link rel="stylesheet" href="/css/application.css" / -->
  </head>
  <body>
    <%
      @yield
    %>
    <!-- script src="/js/application.js"></script -->
  </body>
</html>
```

We can edit it. For example, add this right under the `<body>` tag:

```html
<h1>Welcome to top books</h1>
```

If you reload the page at <http://localhost:8000/bgbooks> you will see the new heading.

But we don't have to stick to the default; we can add additional layouts. Let's suppose that we have for example an admin area which should have a completely different theme. We can add a dedicated layout for that:

```julia
julia> touch("app/layouts/admin.jl.html")
```

Now edit it and make it look like this:

```html
<!-- app/layouts/admin.jl.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Genie Admin</title>
  </head>
  <body>
    <h1>Books admin</h1>
    <%
      @yield
    %>
  </body>
</html>
```

Finally, we must instruct our `BooksController` to use it. The `html!` function takes a third, optional argument, for the layout (a symbol too). Update the `billgatesbooks` function to look like this:

```julia
# BooksController.jl
function billgatesbooks()
  html!(:books, :billgatesbooks, :admin, books = BillGatesBooks)
end
```

Reload the page and you'll see the new heading.

#### @yield

There is a special instruction in the layouts: `@yield`. It outputs the content of the view. So basically where this macro is present, Genie will output the HTML resulting from rendering the view.

### Rendering JSON views

A very common use case for web apps is to serve as backends for RESTful APIs. For this cases, JSON is the preferred data format. You'll be happy to hear that Genie has built in support for JSON responses.

Let's add an endpoint for our API – which will render Bill Gates' books as JSON.

We can start in the `routes.jl` file, by appending this

```julia
route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
```

Next, in `BooksController.jl`, append the extra logic (it should look like this):

```julia
# BooksController.jl
module BooksController

using Genie.Renderer

struct Book
  title::String
  author::String
end

const BillGatesBooks = Book[
  Book("The Best We Could Do", "Thi Bui"),
  Book("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
  Book("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
  Book("The Sympathizer!", "Viet Thanh Nguyen"),
  Book("Energy and Civilization, A History", "Vaclav Smil")
]

function billgatesbooks()
  html!(:books, Symbol("billgatesbooks.jl.html"), books = BillGatesBooks)
end


module API

using ..BooksController
using JSON

function billgatesbooks()
  JSON.json(BooksController.BillGatesBooks)
end

end

end
```

Keep in mind that you're free to organize the code as you see fit – not necessarily like this. It's just one way to do it.

If you go to `http://localhost:8000/api/v1/bgbooks` it should already work.

Not a bad start, but we can do better. First, the mime type of the response is not right. By default Genie will return `text/html`. We need `application/json`. That's easy to fix though, we can just use Genie's `respond` method. The `API` submodule should look like this:

```julia
module API

using ..BooksController
using Genie.Renderer
using JSON

function billgatesbooks()
  respond(JSON.json(BooksController.BillGatesBooks), "application/json")
end

end
```

If you reload the "page", you'll get a proper JSON response. Great!

---

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone. The solution is to, again, use views, to fully control how we render our data – and decouple the data structure from its rendering on the web.

#### JSON views

Genie has support for JSON views – these are plain Julia files which have the ".json.jl" extension. Let's add one in our `views/` folder:

```julia
julia> touch("app/resources/books/views/billgatesbooks.json.jl")
```

We can now create a proper response. Put this in the newly created view file:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill Gates' list of recommended books" => @vars(:books)
```

Final step, instructing `BooksController` to render the view:

```julia
function billgatesbooks()
  json!(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
end
```

This should hold no surprises – the `json!` function is similar to the `html!` one we've seen before.

That's all – everything should work!

A word of warning: the two `billgatesbooks` are very similar, up to the point where the code can't be considered DRY. There are better ways of implementing this in Genie, using a single method and branching the response based entirely on the request. But for now, let's keep it simple.

---

#### Why JSON views have the extension ending in `.jl` but HTML and Markdown views do not?

Good question! The extension of the views is chosen in order to preserve correct syntax highlighting in the IDE. Since practically HTML and Markdown views are HTML and Markdown files with some embeded Julia code, we want to use the HTML or Markdown syntax highlighting. For JSON views, we use pure Julia, so we want Julia syntax highlighting.

---

## Accessing databases with SeachLight models

You can get the most out of Genie and develop high-class-kick-butt web apps by pairing it with its twin brother, SearchLight. SearchLight, a native Julia ORM, provides excellent support for working with relational databases. The Genie + SearchLight combo can be used to productively develop CRUD based apps (CRUD stands for Create-Read-Update-Delete and describes the data workflow in the apps).

SearchLight represents the "M" part in Genie's MVC architecture.

Let's begin by adding SearchLight to our Genie app. All Genie apps manage their dependencies in their own environment, through their `Project.toml` and `Manifest.toml` files. So you need to make sure that you're in `pkg> ` shell mode first (which is entered by typing `]` in julian mode, ie: `julia>]`). The cursor should change to `(MyGenieApp) pkg>`.

Next, we add `SearchLight`:

```julia
(MyGenieApp) pkg> add https://github.com/essenciary/SearchLight.jl
```

### Setup the database connection

Genie is designed to seamlessly integrate with SearchLight – thus, in the "config/" folder there's a DB configuration file already waiting for us: "config/database.yml". Make the file to look like this:

```yaml
env: dev

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```

Now we can ask SearchLight to load it up:

```julia
julia> using SearchLight
julia> SearchLight.Configuration.load_db_connection()
Dict{String,Any} with 3 entries:
  "config"   => nothing
  "database" => "db/books.sqlite"
  "adapter"  => "SQLite"
```

Let's just go ahead and try it out by connecting to the DB:

```julia
julia> SearchLight.Configuration.load_db_connection() |> SearchLight.Database.connect!
SQLite.DB("db/books.sqlite")
```

Awesome! If all went well you should have a `books.sqlite` database in the "db/" folder.

### Managing the database schema with SearchLight migrations

Database migrations provide a way to reliably, consistently and repeatedly apply (and undo) schema transformations. They are basically specialised scripts for adding, removing and altering DB tables – these scripts are placed under version control and are managed by a dedicated system which knows which scripts have been run and which not, and is able to run them in the correct order.

SearchLight needs its own DB table to keep track of the state of the migrations so let's set it up:

```julia
julia> SearchLight.db_init()
[info]: SQL QUERY: CREATE TABLE `schema_migrations` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  )
[info]: Created table schema_migrations
```

### Creating our Book model

SearchLight, just like Genie, uses the convention-over-configuration design pattern. It prefers for things to be setup in a certain way and provides sensible defaults, versus having to define everything in extensive configuration files. And fortunately, we don't even have to remember what these conventions are, as SearchLight also comes with an extensive set of generators. Lets ask SearchLight to create our model:

```julia
julia> SearchLight.Generator.new_resource("Book")

[info]: New model created at /path/to/MyGenieApp/app/resources/books/Books.jl
[info]: New table migration created at /path/to/MyGenieApp/db/migrations/2018100120160530_create_table_books.jl
[info]: New validator created at /path/to/MyGenieApp/app/resources/books/BooksValidator.jl
[info]: New unit test created at /path/to/MyGenieApp/test/unit/books_test.jl
[warn]: Can't write to app info
```

SearchLight has created the `Books.jl` model, the `*_create_table_books.jl` migration file, the `BooksValidator.jl` model validator and the `books_test.jl` test file. The `*_create_table_books.jl` file will be named differently for you as the first part of the name is the timestamp. The timestamp guarantees that names are unique and name clashes are avoided.
Don't worry about the warning, that's meant for SearchLight apps.

#### Writing the table migration

Lets begin by writing the migration to create our books table. SearchLight provides a powerful DSL for writing migrations. Each migration file needs to define two methods: `up` which applies the changes – and `down` which undoes the effects of the `up` method. So in our `up` method we want to create the table – and in `down` we want to drop the table.

The naming convention for tables in SearchLight is that the table name should be pluralized ("books") – because a table contains multiple books. But don't worry, the migration file should already be pre-populated with the correct table name.

Edit the `db/migrations/*_create_table_books.jl` file and make it look like this:

```julia
module CreateTableBooks

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:books) do
    [
      primary_key()
      column(:title, :string)
      column(:author, :string)
    ]
  end

  add_index(:books, :title)
  add_index(:books, :author)
end

function down()
  drop_table(:books)
end

end
```

The DSL is pretty readable: in the `up` function we call `create_table` and pass an array of columns: a primary key, a `title` column and an `author` column. We also add two indices. The `down` method invokes the `drop_table` function to delete the table.

#### Running the migration

We can see what SearchLight knows about our migrations now:

```julia
julia> SearchLight.Migration.status()
|   |                  Module name & status  |
|   |                             File name  |
|---|----------------------------------------|
|   |                 CreateTableBooks: DOWN |
| 1 | 2018100120160530_create_table_books.jl |
```

So our migration is in the down state – meaning that its `up` method has not been run. We can easily fix this:

```julia
julia> SearchLight.Migration.last_up()

[info]: SQL QUERY: CREATE TABLE books (id INTEGER PRIMARY KEY , title VARCHAR , author VARCHAR )
[info]: SQL QUERY: CREATE  INDEX books__idx_title ON books (title)
[info]: SQL QUERY: CREATE  INDEX books__idx_author ON books (author)
[info]: Executed migration CreateTableBooks up
```

If we recheck the status, the migration is up:

```julia
julia> SearchLight.Migration.status()
|   |                  Module name & status  |
|   |                             File name  |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2018100120160530_create_table_books.jl |
```

Our table is ready!

#### Defining the model

Now it's time to edit our model file at "app/resources/books/Books.jl". Another convention in SearchLight is that we're using the pluralized name ("Books") for the module – because it's for managing multiple books. And within it we define a type, called `Book` – which represents an item (a single book) and maps to a row in the underlying database.

The `Books.jl` file should look like this:

```julia
# Books.jl
module Books

using SearchLight, Nullables, SearchLight.Validation, BooksValidator

export Book

mutable struct Book <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String
  _serializable::Vector{Symbol}

  ### FIELDS
  id::DbId
  title::String
  author::String

  ### constructor
  Book(;
    ### FIELDS
    id = DbId(),
    title = "",
    author = ""
  ) = new("books", "id", Symbol[],
          id, title, author
          )
end

end
```

Pretty straightforward: we define a new `mutable struct` which matches our previous `Book` type except that it has a few special fields used by SearchLight. We also define a default keyword constructor as SearchLight needs it.

#### Using our model

To make things more interesting, we should import our current books into the database. Add this function to the `Books.jl` module, under the type definition:

```julia
# Books.jl
function seed()
  BillGatesBooks = [
    ("The Best We Could Do", "Thi Bui"),
    ("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
    ("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
    ("The Sympathizer!", "Viet Thanh Nguyen"),
    ("Energy and Civilization, A History", "Vaclav Smil")
  ]
  for b in BillGatesBooks
    Book(title = b[1], author = b[2]) |> SearchLight.save!
  end
end
```

#### Autoloading the DB configuration

Now, to try things out. Genie takes care of loading all our resource files for us when we load the app. Also, Genie comes with a special file called an initializer, which can automatically load the database configuration and setup SearchLight. Just edit "config/initializers/searchlight.jl" and uncomment the code. It should look like this:

```julia
using SearchLight, SearchLight.QueryBuilder

Core.eval(SearchLight, :(config.db_config_settings = SearchLight.Configuration.load_db_connection()))

SearchLight.Loggers.setup_loggers()
SearchLight.Loggers.empty_log_queue()

if SearchLight.config.db_config_settings["adapter"] != nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end
```

##### Heads up!

All the `.jl` files placed into the `config/initializers/` folder are automatically included by Genie upon starting the Genie app. They are included early (upon initialisation), before the controllers, models, views, are loaded.

#### Trying it out!

Great, now we can start a new Julia REPL within our app's dir and load the app:

```julia
julia>]
pkg> activate .

julia> using Genie
julia> Genie.loadapp()
```

Everything should be loaded now, DB configuration included - so we can invoke the previously defined `seed` function to insert the books:

```julia
julia> using Books
julia> Books.seed()
```

There should be a list of queries showing how the data is inserted in the DB. If you want to make sure, just ask SearchLight to retrieve them:

```julia
julia> SearchLight.all(Book)
julia> 5-element Array{Book,1}:

Book
|    KEY |                                    VALUE |
|--------|------------------------------------------|
| author |                                  Thi Bui |
|     id | Nullable{Union{Int32, Int64, String}}(1) |
|  title |                     The Best We Could Do |

Book
|    KEY |                                            VALUE |
|--------|--------------------------------------------------|
| author |                                  Matthew Desmond |
|     id |         Nullable{Union{Int32, Int64, String}}(2) |
|  title | Evicted: Poverty and Profit in the American City |

# output truncated
```

All good!

The next thing is to update our controller to use the model. Make sure that `app/resources/books/BooksController.jl` reads like this:

```julia
# BooksController.jl
module BooksController

using Genie.Renderer, SearchLight, Books

function billgatesbooks()
  html!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

module API

using ..BooksController
using Genie.Renderer
using SearchLight, Books
using JSON

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

end

end
```

And finally, our JSON view needs a bit of tweaking too:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in @vars(:books)]
```

Now if we just start the server we'll see the list of books served from the database, at <http://localhost:8000/api/v1/bgbooks:>

```julia
julia> MyGenieApp.startup()
```

Let's add a new book to see how it works:

```julia
julia> newbook = Book(title = "Leonardo da Vinci", author = "Walter Isaacson")
julia> SearchLight.save!(newbook)
```

If you reload the page at <http://localhost:8000/bgbooks> the new book should show up.

---

## Handling forms

Now, the problem is that Bill Gates reads – a lot! It would be much easier if we would allow our users to add a few books themselves, to give us a hand. But since, obviously, we're not going to give them access to our Julia REPL, we should setup a webpage with a form. Let's do it.

We'll start by adding the new routes:

```julia
# routes.jl
route("/bgbooks/new", BooksController.new)
route("/bgbooks/create", BooksController.create, method = POST, named = :create_book)
```

The first route will be used to display the page with the new book form. The second will be the target page for submitting our form - this page will accept the form's payload. Please note that it's configured to match `POST` requests and that we gave it a name. We'll use the name in our form so that Genie will dynamically generate the correct links to the corresponding URL (to avoid hard coding URLs). This way we'll make sure that our form will always submit to the right URL, even if we change the route (as long as we don't change the name).

Now, to add the methods in `BooksController`. Add these definition under the `billgatesbooks` function (make sure you add them in `BooksController`, not in `BooksController.API`):

```julia
# BooksController.jl
function new()
  html!(:books, :new)
end

function create()
  # code here
end
```

The `new` method should be clear: we'll just render a view file called `new`. As for `create`, for now it's just a placeholder.

Next, to add our view. Add a blank file called `new.jl.html` in `app/resources/books/views`. Using Julia:

```julia
julia> touch("app/resources/books/views/new.jl.html")
```

Make sure that it has this content:

```html
<!-- app/resources/books/views/new.jl.html -->
<h2>Add a new book recommended by Bill Gates</h2>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books" target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.link_to(:create_book))" method="POST">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="submit" value="Add book" />
</form>
```

Notice that the form's action calls the `link_to` method, passing in the name of the route to generate the URL, resulting in the following HTML: `<form method="POST" action="/bgbooks/create">`.

We should also update the `BooksController.create` method to do something useful with the form data. Let's make it create a new book, persist it to the database and redirect to the list of books. Here is the code:

```julia
# BooksController.jl
using Genie.Router

function create()
  Book(title = @params(:book_title), author = @params(:book_author)) |> save && redirect_to(:get_bgbooks)
end
```

A few things are worth pointing out in this snippet:

* again, we're accessing the `@params` collection to extract the request data, in this case passing in the names of our form's inputs as parameters. We need to bring `Genie.Router` into scope in order to access `@params`;
* we're using the `redirect_to` method to perform a HTTP redirect. As the argument we're passing in the name of the route, just like we did with the form's action. However, we didn't set any route to use this name. It turns out that Genie gives default names to all the routes. We can use these – but a word of notice: **these names are generated using the properties of the route, so if the route changes it's possible that the name will change too**. So either make sure your route stays unchanged – or explicitly name your routes. The autogenerated name, `get_bgbooks` corresponds to the method (GET) and the route ("bgbooks").

In order to get info about the defined routes you can use the `Router.named_routes` function:

```julia
julia> Router.named_routes()
julia> Dict{Symbol,Genie.Router.Route} with 6 entries:
  :get_bgbooks        => Route("GET", "/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :get_bgbooks_new    => Route("GET", "/bgbooks/new", new, Dict{Symbol,Any}(), Function[], Function[])
  :get                => Route("GET", "/", (), Dict{Symbol,Any}(), Function[], Function[])
  :get_api_v1_bgbooks => Route("GET", "/api/v1/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :create_book        => Route("POST", "/bgbooks/create", create, Dict{Symbol,Any}(), Function[], Function[])
  :get_friday         => Route("GET", "/friday", (), Dict{Symbol,Any}(), Function[], Function[])
```

Let's try it out. Input something and submit the form. If everything goes well a new book will be persisted to the database – and it will be added at the bottom of the list of books.

---

## Uploading files

Our app looks great -- but the list of books would be so much better if we'd display the covers as well. Let's do it!

### Modify the database

The first thing we need to do is to modify our table to add a new column, for storing a reference to the name of the cover image. Obviously, we'll use migrations:

```julia
julia> MyGenieApp.newmigration("add cover column")
[debug] New table migration created at db/migrations/2019030813344258_add_cover_column.jl
```

Now we need to edit the migration file - please make it look like this:

```julia
# db/migrations/*_add_cover_column.jl
module AddCoverColumn

import SearchLight.Migrations: add_column, remove_column

function up()
  add_column(:books, :cover, :string)
end

function down()
  remove_column(:books, :cover)
end

end
```

Looking good - lets ask SearchLight to run it:

```julia
julia> SearchLight.Migration.last_up()
[debug] Executed migration AddCoverColumn up
```

If you want to double check, ask SearchLight for the migrations status:

```julia
julia> SearchLight.Migration.status()

|   |                  Module name & status  |
|   |                             File name  |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2018100120160530_create_table_books.jl |
|   |                     AddCoverColumn: UP |
| 2 |   2019030813344258_add_cover_column.jl |
```

Perfect! Now we need to add the new column as a field to the `Books.Book` model:

```julia
module Books

using SearchLight, SearchLight.Validation, BooksValidator

export Book

mutable struct Book <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String
  _serializable::Vector{Symbol}

  ### FIELDS
  id::DbId
  title::String
  author::String
  cover::String

  Book(;
    ### FIELDS
    id = DbId(),
    title = "",
    author = "",
    cover = "",
  ) = new("books", "id", Symbol[],
          id, title, author, cover
          )
end

end
```

As a quick test we can extend our JSON view and see that all goes well - make it look like this:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author,
                                                  "title" => b.title,
                                                  "cover" => b.cover) for b in @vars(:books)]
```

If we navigate <http://localhost:8000/api/v1/bgbooks> you should see the newly added "cover" property (empty, but present).

##### Heads up!

Sometimes Julia/Genie/Revise fails to update `structs` on changes. If you get an error saying that `Book` does not have a `cover` field, please restart the Genie app.

### File uploading

Next step, extending our form to upload images (book covers). Please edit the `new.jl.html` view file as follows:

```html
<h3>Add a new book recommended by Bill Gates</h3>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books" target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.link_to(:create_book))" method="POST" enctype="multipart/form-data">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="file" name="book_cover" /><br />
  <input type="submit" value="Add book" />
</form>
```

The new bits are:

* we added a new attribute to our `<form>` tag: `enctype="multipart/form-data"`. This is required in order to support files payloads.
* there's a new input of type file: `<input type="file" name="book_cover" />`

You can see the updated form by visiting <http://localhost:8000/bgbooks/new>

Now, time to add a new book, with the cover! How about "Identity" by Francis Fukuyama? Sounds good. You can use whatever image you want for the cover, or maybe borrow the one from Bill Gates, I hope he won't mind <https://www.gatesnotes.com/-/media/Images/GoodReadsBookCovers/Identity.png>. Just download the file to your computer so you can upload it through our form.

Almost there - now to add the logic for handling the uploaded file server side. Please update the `BooksController.create` method to look like this:

```julia
# BooksController
function create()
  cover_path = if haskey(filespayload(), "book_cover")
      path = joinpath("img", "covers", filespayload("book_cover").name)
      write(joinpath("public", path), IOBuffer(filespayload("book_cover").data))

      path
    else
      ""
  end

  Book( title = @params(:book_title),
        author = @params(:book_author),
        cover = cover_path) |> save && redirect_to(:get_bgbooks)
end
```

Also, very important, you need to make sure that `BooksController` is `using Genie.Requests`.

Regarding the code, there's nothing very fancy about it. First we check if the files payload contains an entry for our `book_cover` input. If yes, we compute the path where we want to store the file, write the file, and store the path in the database. **Please make sure that you create the folder `covers/` within `public/img/`**.

Great, now let's display the images. Let's start with the HTML view - please edit `app/resources/books/views/billgatesbooks.jl.html` and make sure it has the following content:

```html
<!-- app/resources/books/views/billgatesbooks.jl.html -->
<h1>Bill's Gates top $( length(@vars(:books)) ) recommended books</h1>
<ul>
   <%
      @foreach(@vars(:books)) do book
         """<li><img src="$( isempty(book.cover) ? "img/docs.png" : book.cover )" width="100px" /> $(book.title) by $(book.author)"""
      end
   %>
</ul>
```

Basically here we check if the `cover` property is not empty, and display the actual cover. Otherwise we show a placeholder image. You can check the result at <http://localhost:8000/bgbooks>

As for the JSON view, it already does what we want - you can check that the `cover` property is now outputed, as stored in the database: <http://localhost:8000/api/v1/bgbooks>

Success, we're done here!

#### Heads up!

In production you will have to make the upload code more robust - the big problem here is that we store the cover file as it comes from the user which can lead to name clashes and files being overwritten - not to mention security vulnerabilities. A more robust way would be to compute a hash based on author and title and rename the cover to that.

### One more thing...

So far so good, but what if we want to update the books we have already uploaded? It would be nice to add those missing covers. We need to add a bit of functionality to include editing features.

First things first - let's add the routes. Please add these two new route definitions to the `config/routes.jl` file:

```julia
route("/bgbooks/:id::Int/edit", BooksController.edit)
route("/bgbooks/:id::Int/update", BooksController.update, method = POST, named = :update_book)
```

We defined two new routes. The first will display the book object in the form, for editing. While the second will take care of actually updating the database, server side. For both routes we need to pass the id of the book that we want to edit - and we want to contrain it to an `Int`. We express this as the `/:id::Int/` part of the route.

... TO BE CONTINUED ...

---

## Adding data integrity rules with ModelValidators

TODO

## Caching our responses

TODO

## Using WebSockets and WebChannels

TODO

## Setting up an admin area

---

## Acknowledgements

* Genie uses a multitude of packages that have been kindly contributed by the Julia community.
* The awesome Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
