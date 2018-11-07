![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

[![Stable](https://readthedocs.org/projects/docs/badge/?version=stable)](http://geniejl.readthedocs.io/en/stable/build/)
[![Latest](https://readthedocs.org/projects/docs/badge/?version=latest)](http://geniejl.readthedocs.io/en/latest/build/)

# Genie
### The highly productive Julia web framework
Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.

### Current status
Genie is now compatible with Julia v1.0 (and it's the only version of Julia supported anymore).
This is a recent development (mid September 2018) so more testing is needed.

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

Finally, now navigate to "http://localhost:8000" – you should see the message "Hi there!".

We can define more complex URIs which can also map to previously defined functions:
```julia
julia> function hello_world()
         "Hello World!"
       end
julia> route("/hello/world", hello_world)
```
Obviously, the functions can be defined anywhere (in any other module) as long as they are accessible in the current scope.

You can now visit "http://localhost:8000/hello/world" in the browser.

Of course we can access GET params:
```julia
julia> import Genie.Router: @params
julia> route("/echo/:message") do
         @params(:message)
       end
```

Accessing http://localhost:8000/echo/ciao should echo "ciao".

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

Now if we access http://localhost:8000/sum/2/3 we should see `5`

---

## Working with Genie apps (projects)

Working with Genie in an interactive environment can be useful – but usually we want to persist our application and reload it between sessions. One way to achieve that is to save it as an IJulia notebook and rerun the cells. However, you can get the most of Genie by working with Genie apps. A Genie app is an MVC web application which promotes the convention-over-configuration principle. Which means that by working with a few predefined files, within the Genie app structure, Genie can lift a lot of weight and massively improve development productivity. This includes automatic module loading and reloading, dedicated configuration files, logging, environments, code generators, and more.

In order to create a new app, run:
```julia
julia> Genie.REPL.new_app("your_cool_new_app")
```

Genie will
* create the app,
* install all the dependencies,
* automatically load the new app into the REPL,
* start an interactive `genie>` session,
* and start the web server on the default port (8000)

At this point you can confirm that everything worked as expected by visiting http://localhost:8000 in your favourite web browser. You should see Genie's welcome page.

Next, let's add a new route. This time we need to append it to the dedicated `routes.jl` file. Edit `/path/to/your_cool_new_app/config/routes.jl` in your favourite editor or run the next snippet (making sure you are in the app's directory):

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

Visit `http://localhost:8000/hello` for a warm welcome!

### Loading an app

At any time, you can load and serve an existing Genie app.

##### Julia's REPL
First, make sure that you're in the root dir of the app (there should be a `genie.jl` file there, that's what bootstraps the app).

Then run
```julia
julia> using Genie
julia> Genie.REPL.load_app()
```

The app's environment will now be loaded.

In order to start the web server execute
```julia
julia> Genie.AppServer.startup()
```

##### MacOS / Linux
You can start an interactive REPL in your app's environment by executing `bin/repl` in the os shell.
```sh
$ bin/repl
```
The app's environment will now be loaded.

In order to start the web server execute
```julia
julia> Genie.AppServer.startup()
```

If, instead, you want to directly start the server, use
```sh
$ bin/server
```

##### Windows
On Windows it's similar to the macOS and Linux, but dedicated Windows scripts, `repl.bat` and `server.bat` are provided inside the `bin/` folder.
Double click them or execute them in the os shell to start an interactive REPL session or a server session, respectively.

##### Juno / Jupyter / other Julia environment
First, make sure that you `cd` into your app's root folder (there should be a `genie.jl` file there, that's what bootstraps the app).
```julia
using Genie
Genie.REPL.load_app()
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
Adding your code to the `routes.jl` file or placing it into the `lib/` folder works great for small projects, where you want to quickly publish some features on the web. But for any larger projects we're better off using Genie's MVC structure. By employing the Module View Controller design pattern we can break our code in modules with clear responsabilities. Modular code is easier to write, test and maintain.

---

#### Check the code
The code for the example app being built in the upcoming paragraphs can be accessed at: https://github.com/essenciary/Genie-Searchlight-example-app

---

A Genie app is structured around the concept of "resources". A resource represents a business entity (something like a user, or a product, or an account) and maps to a bundle of files (controller, model, views, etc).

Resources live under `app/resources/`. For example, if we have a web app about "books", a "books/" folder would be placed in `app/resources/` and would contain all the files for publishing books on the web.

### Using Controllers
Controllers are used to orchestrate interactions between client requests, models (DB access), and views (response rendering). In a standard workflow a route points to a method in the controller – which is responsible for building and sending the response.

Let's add a "books" controller. We could do it by hand – but Genie comes with handy generators which will happily do the boring work for us.

#### Generate the Controller
Let's generate our `BooksController`:
```julia
genie> Genie.REPL.new_controller("Books")
[info]: New controller created at app/resources/books/BooksController.jl
```

Great! Let's edit `BooksController.jl` and add something to it. For example, a function which returns somf of Bill Gates' recommended books would be nice. Make sure that `BooksController.jl` looks like this:
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

Genie supports a special type of HTML view, where we can embed Julia code. These are high performance compiled views. They are not parsed as strings: instead, the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file. Hence, the first time you load a view or ofter you change one, you might notice a certain delay – it's the time needed to generate and compile the view. On next runs (especially in production) it's blazing fast!

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

It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, your Julia code _must return a string_ as the result, so that the output of your computation comes up on the page.

Genie provides a series of helpers, like the above used `@foreach` macro.

Also, very important, please notice the `@vars` macro. This is used to access variables which are passed from the controller into the view. We'll see how to do this right now.

#### Rendering views
We now need to refactor our controller to use the view, passing in the expected variables. We will use the `html!` method which renders and outputs the response. Update the definition of the `billgatesbooks` function to be as follows:
```julia
# BooksController.jl
function billgatesbooks()
  html!(:books, :billgatesbooks, books = BillGatesBooks)
end
```

We also need to add `Genie.Router` as a dependency, to get access to the `html!` method. So add this at the top of the `BooksController` module:
```julia
using Genie.Renderer
```

The `html!` function takes as its arguments:
* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file)
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out
* and finally, we pass the values we want to expose in the view, as keyword arguments. In this scenario, the `books` keyword argument – which will be available in the view file under `@args(:books)`.

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

Notice that Markdown views do not support the embedded Julia tags `<% ... %>`. Only string interpolation `$(...)` is accepted and it works across multiple lines.

If you reload the page now, however, Genie will still load the HTML view. The reason is that, _if we have only one view file_, Genie will manage. But if there's more than one, the framework won't know which one to pick. It won't error out but will pick the preferred one, which is the HTML version.

It's a simple change in the `BookiesController`: we have to explicitly tell Genie which file to load, extension and all:
```julia
# BooksController.jl
function billgatesbooks()
  html!(:books, Symbol("billgatesbooks.jl.md"), books = BillGatesBooks)
end
```

** Please keep in mind that Markdown files are not compiled, nor cached, so the performance _will_ be affected. **

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
Genie's views are rendered within a layout file. Layouts are meant to render the theme of the website – the elements which are common on all the pages. It can include visible elements, like the main menu or the footer. But also maybe the `<head>` tag or the assets tags (`<link>` and `<script>` tags for loading CSS and JavaScript files).

Every Genie app has a main layout file which is used by default – it can be found in `app/layouts/` and it's called `app.jl.html`. It looks like this:
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

If you reload the page at `http://localhost:8000/bgbooks` you will see the new heading.

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


### Rendering JSON
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

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone. The solution is to, again, use views, to fully control how we render our data – and decouple the data structure from its rendering on the web.

#### JSON views
Genie has support for JSON views – these are plain Julia files which have the ".json.jl" extension. Let's add one in our `views/` folder:
```julia
julia> touch("app/resources/books/views/billgatesbooks.json.jl")
```

We can now create a proper response. Put this in the newly created view file:
```julia
# app/resources/books/views/billgatesbooks.json.jl
Dict(
  "Bill Gates' list of recommended books" => @vars(:books)
)
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

## Accessing databases with SeachLight models
You can get the most out of Genie and develop high-class-kick-butt web apps by pairing it with its twin brother, SearchLight. Genie has excellent support for working with relational databases through its tight integration with SearchLight, a native Julia ORM, which was initially developed as part of Genie itself. The Genie + SearchLight combo can be used to productively develop CRUD based apps (CRUD stands for Create-Read-Update-Delete and describes the data workflow in the apps).

SearchLight represents the "M" part in Genie's MVC architecture.

Let's begin by adding SearchLight to our Genie app. All Genie apps manage their dependencies in their own environment, through their `Project.toml` and `Manifest.toml` files. So you need to make sure that you're in `pkg> ` shell mode first and that our books project is loaded. You do this by running `pkg> activate .` in the root folder of the app. Next, we add SearchLight:
```julia
pkg> add https://github.com/essenciary/SearchLight.jl
```

### Setup the database connection
As I was saying, Genie is made to integrate with SearchLight – thus, in the "config/" folder there's a DB configuration file already waiting for us: "config/database.yml". Update the top part of the file to look like this:
```yaml
env: dev

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```

Now we can ask SearchLight to load it up like this:
```julia
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
[info | SearchLight.Loggers]: SQL QUERY: CREATE TABLE `schema_migrations` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  )
[info | SearchLight.Loggers]: Created table schema_migrations
```

### Creating our Book model
SearchLight, just like Genie, uses the convention-over-configuration design pattern. It prefers for things to be setup in a certain way and provides sensible defaults, versus having to define everything in extensive configuration files. And fortunately, we don't even have to remember what these conventions are, as SearchLight also comes with an extensive set of generators. Lets ask SearchLight to create our model:
```julia
julia> SearchLight.Generator.new_resource("Book")
[info | SearchLight.Loggers]: New model created at /Users/adrian/Dropbox/Projects/testapp/app/resources/books/Books.jl
[info | SearchLight.Loggers]: New table migration created at /Users/adrian/Dropbox/Projects/testapp/db/migrations/2018100120160530_create_table_books.jl
[info | SearchLight.Loggers]: New validator created at /Users/adrian/Dropbox/Projects/testapp/app/resources/books/BooksValidator.jl
[info | SearchLight.Loggers]: New unit test created at /Users/adrian/Dropbox/Projects/testapp/test/unit/books_test.jl
[warn | SearchLight.Loggers]: Can't write to app info
```

SearchLight has created the `Books.jl` model, the \*2018100120160530_create_table_books.jl migration file, the `BooksValidator.jl` model validator and the `books_test.jl` test file. Don't worry about the warning, that's meant for SearchLight apps.

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
We can see what SearchLight knows about our migrations with:
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
[info | SearchLight.Loggers]: SQL QUERY: CREATE TABLE books (id INTEGER PRIMARY KEY , title VARCHAR , author VARCHAR )
[info | SearchLight.Loggers]: SQL QUERY: CREATE  INDEX books__idx_title ON books (title)
[info | SearchLight.Loggers]: SQL QUERY: CREATE  INDEX books__idx_author ON books (author)
[info | SearchLight.Loggers]: Executed migration CreateTableBooks up
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
Now it's time to edit our model file at "app/resources/books/Books.jl". Another convention in SearchLight is that we're using the pluralized name ("Books") for the module – because it's for managing multiple books. And within it we define a type, called `Book` – which represents an item and maps to a row in the underlying database.

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

Pretty straightforward stuff: we define a new `mutable struct` which matches our previous `Book` type except that it has a few special fields used by SearchLight. We also define a default keyword constructor as SearchLight needs it.

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

Core.eval(Genie.Generator, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.Tester, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.Commands, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.REPL, :(using SearchLight, SearchLight.Generator, SearchLight.Migration))
```

#### Trying it out!
Great, now we can start a new REPL with our app:
```
pkg> activate .
julia> using Genie
julia> Genie.REPL.load_app()
```

Everything should be loaded now:
```julia
genie> using Books
genie> Books.seed()
```
There should be a list of queries showing how the data is inserted in the DB. If you want to make sure, just ask SearchLight to retrieve them:
```julia
genie> SearchLight.all(Book)
genie> 5-element Array{Book,1}:

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

The last thing is to update our controller to use the model. Make sure that `app/resources/books/BooksController.jl` reads like this:
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
using JSON

function billgatesbooks()
  json!(:books, :billgatesbooks, books = SearchLight.all(Book))
end

end

end
```

Now if we just start the server we'll see the list of books served from the database.

Let's add a new book to see how it works:
```julia
newbook = Book(title = "Leonardo da Vinci", author = "Walter Isaacson")
SearchLight.save!(newbook)
```

If you reload the page at http://localhost:8000/bgbooks the new book should show up.

---

## Handling forms
Now, the problem is that Bill Gates reads – a lot! It would be much easier if we would allow our users to add a few books themselves, to give us a hand. But since, obviously, we're not going to give them access to our Julia REPL, we should setup a webpage with a form. Let's do it.

We'll start by adding the new routes:
```julia
# routes.jl
route("/bgbooks/new", BooksController.new)
route("/bgbooks/create", BooksController.create, method = POST, named = :create_book)
```
The first route will be used to display the page with the new book form. The second will be the target page for submitting our form - this page will accept the form's payload. Please note that it's configured to match `POST` requests and that we gave it a name. We'll use the name in our form so that Genie will dynamically generate the correct link. This way we'll make sure that our form will always submit to the right URL, even if we change the route (as long as we don't change the name).

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

Finally, to add our view. Add a blank file called `new.jl.html` in `app/resources/books/views`. Using Julia:
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
* we're using the `redirect_to` method to perform a HTTP redirect. As the argument we're passing in the name of the route, just like we did with the form's action. However, we didn't set any route to use this name. It turns out that Genie gives default names to all the routes. We can use these – but a word of notice: these names are generated using the properties of the route, so if the route changes it's possible that the name will change too. So either make sure your route stays unchanged – or explicitly name your routes.
In order to get info about the defined routes you can use the `Router.named_routes` function:
```julia
genie> Router.named_routes()
genie> Dict{Symbol,Genie.Router.Route} with 6 entries:
  :get_bgbooks        => Route("GET", "/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :get_bgbooks_new    => Route("GET", "/bgbooks/new", new, Dict{Symbol,Any}(), Function[], Function[])
  :get                => Route("GET", "/", (), Dict{Symbol,Any}(), Function[], Function[])
  :get_api_v1_bgbooks => Route("GET", "/api/v1/bgbooks", billgatesbooks, Dict{Symbol,Any}(), Function[], Function[])
  :create_book        => Route("POST", "/bgbooks/create", create, Dict{Symbol,Any}(), Function[], Function[])
  :get_friday         => Route("GET", "/friday", (), Dict{Symbol,Any}(), Function[], Function[])
```

Let's try it out. Input something and submit the form. If everything goes well a new book will be persisted to the database – and it will be added at the bottom of the list of books.

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
