# Working with Genie apps (projects)

Working with Genie in an interactive environment can be useful – but usually we want to persist the application and reuse it between sessions. One way to achieve this is to save it as an IJulia notebook and rerun the cells.

However, you can get the best of Genie by working with Genie apps. A Genie app is a MVC (Model-View-Controller) web application which promotes the convention-over-configuration principle. By working with a few predefined files, within the Genie app structure, the framework can lift a lot of weight and massively improve development productivity. But following Genie's workflow, one instantly gets, out of the box, features like automatic module loading and reloading, dedicated configuration files, logging, support for environments, code generators, caching, support for Genie plugins, and more.

In order to create a new Genie app, we need to run `Genie.newapp($app_name)`:

```julia
julia> Genie.newapp("MyGenieApp")
```

Upon executing the command, Genie will:

* make a new dir called `MyGenieApp` and `cd()` into it,
* install all the app's dependencies,
* create a new Julia project (adding the `Project.toml` and `Manifest.toml` files),
* activate the project,
* automatically load the new app's environment into the REPL,
* start the web server on the default Genie port (port 8000) and host (127.0.0.1).

At this point you can confirm that everything worked as expected by visiting <http://127.0.0.1:8000> in your favourite web browser. You should see Genie's welcome page.

Next, let's add a new route. Routes are used to map request URLs to Julia functions. These functions provide the response that will be sent back to the client. Routes are meant to be defined in the dedicated `routes.jl` file. Open `MyGenieApp/routes.jl` in your editor or run the following command (making sure that you are in the app's directory):

```julia
julia> edit("routes.jl")
```

Append this at the bottom of the `routes.jl` file and save it:

```julia
# routes.jl
route("/hello") do
  "Welcome to Genie!"
end
```

We are using the `route` method, passing in the "/hello" URL and an anonymous function which returns the string "Welcome to Genie!". What this means is that for each request to the "/hello" URL, our app will invoke the route handler function and respond with the welcome message.

Visit <http://127.0.0.1:8000/hello> for a warm welcome!

## Working with resources

Adding our code to the `routes.jl` file works great for small projects, where you want to quickly publish features on the web. But for larger projects we're better off using Genie's MVC structure (MVC stands for Model-View-Controller). By employing the Model-View-Controller design pattern we can break our code into modules with clear responsibilities: the Model is used for data access, the View renders the response to the client, and the Controller orchestrates the interactions between Models and Views and handles requests. Modular code is easier to write, test and maintain.

A Genie app can be architected around the concept of "resources". A resource represents a business entity (something like a user, or a product, or an account) and maps to a bundle of files (controller, model, views, etc). Resources live under the `app/resources/` folder and each resource has its own dedicated folder, where all of its files are hosted. For example, if we have a web app about "books", a "books" folder would be found at `app/resources/books` and will contain all the files for publishing books on the web (usually called `BooksController.jl` for the controller, `Books.jl` for the model, `BooksValidator.jl` for the model validator -- as well as a `views` folder for hosting all the view files necessary for rendering books data).

---
**HEADS UP**

When creating a default Genie app, the `app/` folder might be missing. It will be automatically created the first time you add a resource via Genie's generators.

---

## Using Controllers

Controllers are used to orchestrate interactions between client requests, Models (which handle data access), and Views (which are responsible for rendering the responses which will be sent to the clients' web browsers). In a standard workflow, a `route` points to a method in the controller – which is charged with building and sending the response over the network, back to the client.

Let's add a "books" controller. Genie comes with handy generators and one of them is for creating new controllers:

### Generate the Controller

Let's generate our `BooksController`:

```julia
julia> Genie.newcontroller("Books")
[info]: New controller created at ./app/resources/books/BooksController.jl
```

Great! Let's edit `BooksController.jl` (`julia> edit("./app/resources/books/BooksController.jl")`) and add something to it. For example, a function which returns some of Bill Gates' recommended books would be nice. Make sure that `BooksController.jl` looks like this:

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
  "
  <h1>Bill Gates' list of recommended books</h1>
  <ul>
    $(["<li>$(book.title) by $(book.author)</li>" for book in BillGatesBooks]...)
  </ul>
  "
end

end
```

Our controller is just a plain Julia module where we define a `Book` type/struct and set up an array of book objects. We then defined a function, `billgatesbooks`, which returns an HTML string, with a `H1` heading and an unordered list of all the books. We used an array comprehension to iterate over each book and render it in a `<li>` element. The elements of the array are then concatenated using the splat `...` operator.
The plan is to map this function to a route and expose it on the internet.

#### Checkpoint

Before exposing it on the web, we can test the function in the REPL:

```julia
julia> using BooksController

julia> BooksController.billgatesbooks()
```

The output of the function call should be a HTML string which looks like this:

```julia
"\n  <h1>Bill Gates' list of recommended books</h1>\n  <ul>\n    <li>The Best We Could Do by Thi Bui</li><li>Evicted: Poverty and Profit in the American City by Matthew Desmond</li><li>Believe Me: A Memoir of Love, Death, and Jazz Chickens by Eddie Izzard</li><li>The Sympathizer by Viet Thanh Nguyen</li><li>Energy and Civilization, A History by Vaclav Smil</li>\n  </ul>\n"
```

Please make sure that it works as expected.

### Setup the route

Now, let's expose our `billgatesbooks` method on the web. We need to add a new `route` which points to it. Add these to the `routes.jl` file:

```julia
# routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```

In the snippet we declared that we're `using BooksController` (notice that Genie will know where to find it, no need to explicitly include the file) and then we defined a `route` between `/bgbooks` and the `BooksController.billgatesbooks` function (we say that the `BooksController.billgatesbooks` is the route handler for the `/bgbooks` URL or endpoint).

That's all! If you now visit `http://localhost:8000/bgbooks` you'll see Bill Gates' list of recommended books (well, at least some of them, the man reads a lot!).

---
**PRO TIP**

If you would rather work with Julia instead of wrangling HTML strings, you can use Genie's `Html` API. It provides functions which map every standard HTML element. For instance, the `BooksController.billgatesbooks` function can be written as follows, as an array of HTML elements:

```julia
using Genie.Renderer.Html

function billgatesbooks()
  [
    Html.h1() do
      "Bill Gates' list of recommended books"
    end
    Html.ul() do
      @foreach(BillGatesBooks) do book
        Html.li() do
          book.title * " by " * book.author
        end
      end
    end
  ]
end
```

The `@foreach` macro iterates over a collection and concatenates the output of each loop into the result of the loop. We'll talk about it more soon.

---

### Adding views

However, putting HTML into the controllers is a bad idea: HTML should stay in the dedicated view files and contain as little logic as possible. Let's refactor our code to use views instead.

The views used for rendering a resource should be placed inside the `views/` folder, within that resource's own folder structure.
So in our case, we will add an `app/resources/books/views/` folder. Just go ahead and do it, Genie does not provide a generator for this task:

```julia
julia> mkdir(joinpath("app", "resources", "books", "views"))
"app/resources/books/views"
```

We created the `views/` folder in `app/resources/books/`. We provided the full path as our REPL is running in the the root folder of the app. Also, we use the `joinpath` function so that Julia creates the path in a cross-platform way.

### Naming views

Usually each controller method will have its own rendering logic – hence, its own view file. Thus, it's a good practice to name the view files just like the methods, so that we can keep track of where they're used.

At the moment, Genie supports HTML and Markdown view files, as well as plain Julia. Their type is identified by file extension so that's an important part.
The HTML views use a `.jl.html` extension while the Markdown files go with `.jl.md` and the Julia ones by `.jl`.

### HTML views

All right then, let's add our first view file for the `BooksController.billgatesbooks` method. Let's create an HTML view file. With Julia:

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.html"))
```

Genie supports a special type of dynamic HTML view, where we can embed Julia code. These are high performance compiled views. They are _not_ parsed as strings: instead, **the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file**.
Hence, the first time you load a view, or after you change one, you might notice a certain delay – it's the time needed to generate, compile and load the view.
On next runs (especially in production) it's going to be blazing fast!

Now all we need to do is to move the HTML code out of the controller and into the view, improving it a bit to also show a count of the number of books. Edit the view file as follows (`julia> edit("app/resources/books/views/billgatesbooks.jl.html")`):

```html
<!-- billgatesbooks.jl.html -->
<h1>Bill Gates' top $(length(books)) recommended books</h1>
<ul>
  <% @foreach(books) do book %>
    <li>$(book.title) by $(book.author)</li>
  <% end %>
</ul>
```

As you can see, it's just plain HTML with embedded Julia. We can add Julia code by using the `<% ... %>` code block tags – these should be used for more complex, multiline expressions. Or by using plain Julia string interpolation with `$(...)` – for simple values outputting.

To make HTML generation more efficient, Genie provides a series of helpers, like the above `@foreach` macro which allows iterating over a collection, passing the current item into the processing function.

---
**HEADS UP**

**It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, the Julia view code _must return a string_ as its result, so that the output of the computation comes up on the page**. Given that Julia automatically returns the result of the last computation, most of the times this just flows naturally. But if sometimes you notice that the templates don't output what is expected, do check that the code returns a string (or something which can be converted to a string).

---

### Rendering views

We now need to refactor our controller to use the view, passing in the expected variables. We will use the `html` method which renders and outputs the response as HTML. Update the definition of the `billgatesbooks` function to be as follows:

```julia
# BooksController.jl
using Genie.Renderer.Html

function billgatesbooks()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end
```

First, notice that we needed to add `Genie.Renderer.Html` as a dependency, to get access to the `html` method. As for the `html` method itself, it takes as its arguments the name of the resource, the name of the view file, and a list of keyword arguments representing view variables:

* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file -- in our case `app/resources/books/views`);
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out since there's only one file with this name;
* and finally, we pass the values we want to expose in the view, as keyword arguments.

That's it – our refactored app should be ready! You can try it out for yourself at <http://localhost:8000/bgbooks>

### Markdown views

Markdown views work similar to HTML views – employing the same embedded Julia functionality. Here is how you can add a Markdown view for our `billgatesbooks` function.

First, create the corresponding view file, using the `.jl.md` extension. Maybe with:

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.md"))
```

Now edit the file and make sure it looks like this:

```md
<!-- app/resources/books/views/billgatesbooks.jl.md -->
# Bill Gates' $(length(books)) recommended books

$(
  @foreach(books) do book
    "* $(book.title) by $(book.author) \n"
  end
)
```

Notice that Markdown views do not support Genie's embedded Julia tags `<% ... %>`. Only string interpolation `$(...)` is accepted, but it works across multiple lines.

If you reload the page now, however, Genie will still load the HTML view. The reason is that, _if we have only one view file_, Genie will manage.
But if there's more than one, the framework won't know which one to pick. It won't error out but will pick the preferred one, which is the HTML version.

It's a simple change in the `BookiesController`: we have to explicitly tell Genie which file to load, extension and all:

```julia
# BooksController.jl
function billgatesbooks()
  html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
end
```

### Taking advantage of layouts

Genie's views are rendered within a layout file. Layouts are meant to render the theme of the website, or the "frame" around the view – the elements which are common on all the pages. The layout file can include visible elements, like the main menu or the footer. But also maybe the `<head>` tag or the assets tags (`<link>` and `<script>` tags for loading CSS and JavaScript files in all the pages).

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

We can edit it. For example, add this right under the opening `<body>` tag, just above the `<%` tag:

```html
<h1>Welcome to top books</h1>
```

If you reload the page at <http://localhost:8000/bgbooks> you will see the new heading.

But we don't have to stick to the default; we can add additional layouts. Let's suppose that we have, for example, an admin area which should have a completely different theme.
We can add a dedicated layout for that:

```julia
julia> touch(joinpath("app", "layouts", "admin.jl.html"))
"app/layouts/admin.jl.html"
```

Now edit it (`julia> edit("app/layouts/admin.jl.html")`) and make it look like this:

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

If we want to apply it, we must instruct our `BooksController` to use it. The `html` function takes a keyword argument named `layout`, for the layout file.
Update the `billgatesbooks` function to look like this:

```julia
# BooksController.jl
function billgatesbooks()
  html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
end
```

Reload the page and you'll see the new heading.

#### The `@yield` instruction

There is a special instruction in the layouts: `@yield`. It outputs the contents of the view as rendered through the controller. So where this macro is present, Genie will output the HTML resulting from rendering the view by executing the route handler function within the controller.

#### Using view paths

For very simple applications the MVC and the resource-centric approaches might involve too much boilerplate. In such cases, we can simplify the code by referencing the view (and layout) by file path, ex:

```julia
# BooksController.jl
using Genie.Renderer

function billgatesbooks()
  html(path"app/resources/books/views/billgatesbooks.jl.html", books = BillGatesBooks, layout = path"app/layouts/app.jl.html")
end
```

### Rendering JSON views

A common use case for web apps is to serve as backends for RESTful APIs. For this cases, JSON is the preferred data format. You'll be happy to hear that Genie has built-in support for JSON responses. Let's add an endpoint for our API – which will render Bill Gates' books as JSON.

We can start in the `routes.jl` file, by appending this

```julia
route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
```

Next, in `BooksController.jl`, append the extra logic at the end of the file, before the closing `end`. The whole file should look like this:

```julia
# BooksController.jl
module BooksController

using Genie.Renderer.Html

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
  html(:books, :billgatesbooks, layout = :admin, books = BillGatesBooks)
end


module API

using ..BooksController
using Genie.Renderer.Json

function billgatesbooks()
  json(BooksController.BillGatesBooks)
end

end
```

We nested an API module within the `BooksController` module, where we defined another `billgatesbooks` function which outputs a JSON.

If you go to `http://localhost:8000/api/v1/bgbooks` it should already work as expected.

#### JSON views

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone as any changes in the data will break the client's integrations. The solution is to, again, use views, to fully control how we render our data – and decouple the data structure from its rendering on the web.

Genie has support for JSON views – these are plain Julia files which have the ".json.jl" extension. Let's add one in our `views/` folder:

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.json.jl"))
"app/resources/books/views/billgatesbooks.json.jl"
```

We can now create a proper response. Put this in the view file:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill Gates' list of recommended books" => books
```

Final step, instructing `BooksController` to render the view. Simply replace the existing `billgatesbooks` function within the `API` sub-module with the following:

```julia
function billgatesbooks()
  json(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
end
```

This should hold no surprises – the `json` function is similar to the `html` one we've seen before. So now we're rendering a custom JSON response. That's all – everything should work!

---
**HEADS UP**

#### Why JSON views have the extension ending in `.jl` but HTML and Markdown views do not?

Good question! The extension of the views is chosen in order to preserve correct syntax highlighting in the IDE/code editor.

Since practically HTML and Markdown views are HTML and Markdown files with some embedded Julia code, we want to use the HTML or Markdown syntax highlighting. For JSON views, we use pure Julia, so we want Julia syntax highlighting.

---

## Accessing databases with `SeachLight` models

You can get the most out of Genie by pairing it with its seamless ORM layer, SearchLight. SearchLight, a native Julia ORM, provides excellent support for working with relational databases. The Genie + SearchLight combo can be used to productively develop CRUD (Create-Read-Update-Delete) apps.

---
**HEADS UP**

CRUD stands for Create-Read-Update-Delete and describes the data workflow in many web apps, where resources are created, read (listed), updated, and deleted.

---

SearchLight represents the "M" part in Genie's MVC architecture (thus, the Model layer).

Let's begin by adding SearchLight to our Genie app. All Genie apps manage their dependencies in their own Julia environment, through their `Project.toml` and `Manifest.toml` files.

So we need to make sure that we're in `pkg> ` shell mode first (which is entered by typing `]` in julian mode, ie: `julia>]`).
The cursor should change to `(MyGenieApp) pkg>`.

Next, we add `SearchLight`:

```julia
(MyGenieApp) pkg> add SearchLight
```

### Adding a database adapter

`SearchLight` provides a database agnostic API for working with various backends (at the moment, MySQL, SQLite, and Postgres). Thus, we also need to add the specific adapter. To keep things simple, let's use SQLite for our app. Hence, we'll need the `SearchLightSQLite` package:

```julia
(MyGenieApp) pkg> add SearchLightSQLite
```

### Setup the database connection

Genie is designed to seamlessly integrate with SearchLight and provides access to various database oriented generators. First we need to tell Genie/SearchLight how to connect to the database. Let's use them to set up our database support. Run this in the Genie/Julia REPL:

```julia
julia> Genie.Generator.db_support()
```

The command will add a `db/` folder within the root of the app. What we're looking for is the `db/connection.yml` file which tells SearchLight how to connect to the database. Let's edit it. Make the file look like this:

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```

This instructs SearchLight to run in the environment of the current Genie app (by default `dev`), using `SQLite` for the adapter (backend) and a database stored at `db/books.sqlite` (the database will be created automatically if it does not exist). We could pass extra configuration options in the `config` object, but for now we don't need anything else.

---
**HEADS UP**

If you are using a different adapter, make sure that the database configured already exists and that the configured user can successfully access it -- SearchLight will not attempt to create the database.

---

Now we can ask SearchLight to load it up:

```julia
julia> using SearchLight

julia> SearchLight.Configuration.load()
Dict{String,Any} with 4 entries:
  "options"  => Dict{String,String}()
  "config"   => nothing
  "database" => "db/books.sqlite"
  "adapter"  => "SQLite"
```

Let's just go ahead and try it out by connecting to the DB:

```julia
julia> using SearchLightSQLite

julia> SearchLight.Configuration.load() |> SearchLight.connect
SQLite.DB("db/books.sqlite")
```

The connection succeeded and we got back a SQLite database handle.

---
**PRO TIP**

Each database adapter exposes a `CONNECTIONS` collection where we can access the connection:

```julia
julia> SearchLightSQLite.CONNECTIONS
1-element Array{SQLite.DB,1}:
 SQLite.DB("db/books.sqlite")
```

---

Awesome! If all went well you should have a `books.sqlite` database in the `db/` folder.

```julia
shell> tree db
db
├── books.sqlite
├── connection.yml
├── migrations
└── seeds
```

### Managing the database schema with `SearchLight` migrations

Database migrations provide a way to reliably, consistently and repeatedly apply (and undo) schema transformations. They are specialised scripts for adding, removing and altering DB tables – these scripts are placed under version control and are managed by a dedicated system which knows which scripts have been run and which not, and is able to run them in the correct order.

SearchLight needs its own DB table to keep track of the state of the migrations so let's set it up:

```julia
julia> SearchLight.Migrations.create_migrations_table()
[ Info: Created table schema_migrations
```

This command sets up our database with the needed table in order to manage migrations.

---
**PRO TIP**

You can use the SearchLight API to execute random queries against the database backend. For example we can confirm that the table is really there:

```julia
julia> SearchLight.query("SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'")
┌ Info: SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'
└

1×1 DataFrames.DataFrame
│ Row │ name              │
│     │ String⍰           │
├─────┼───────────────────┤
│ 1   │ schema_migrations │
```

The result is a familiar `DataFrame` object.

---

### Creating our Book model

SearchLight, just like Genie, uses the convention-over-configuration design pattern. It prefers for things to be setup in a certain way and provides sensible defaults, versus having to define everything in extensive configuration files. And fortunately, we don't even have to remember what these conventions are, as SearchLight also comes with an extensive set of generators.

Lets ask SearchLight to create a new model:

```julia
julia> SearchLight.Generator.newmodel("Book")

[ Info: New model created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/Books.jl
[ Info: New table migration created at /Users/adrian/Dropbox/Projects/MyGenieApp/db/migrations/2020020909574048_create_table_books.jl
[ Info: New validator created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/BooksValidator.jl
[ Info: New unit test created at /Users/adrian/Dropbox/Projects/MyGenieApp/test/books_test.jl
```

SearchLight has created the `Books.jl` model, the `*_create_table_books.jl` migration file, the `BooksValidator.jl` model validator and the `books_test.jl` test file.

---
**HEADS UP**

The first part of the migration file will be different for you!

The `*_create_table_books.jl` file will be named differently as the first part of the name is the file creation timestamp. This timestamp part guarantees that names are unique and file name clashes are avoided (for example when working as a team a creating similar migration files).

---


#### Writing the table migration

Lets begin by writing the migration to create our books table. SearchLight provides a powerful DSL for writing migrations.
Each migration file needs to define two methods: `up` which applies the changes – and `down` which undoes the effects of the `up` method.
So in our `up` method we want to create the table – and in `down` we want to drop the table.

The naming convention for tables in SearchLight is that the table name should be pluralized (`books`) – because a table contains multiple books (each row represents an object, a "book").
But don't worry, the migration file should already be pre-populated with the correct table name.

Edit the `db/migrations/*_create_table_books.jl` file and make it look like this:

```julia
module CreateTableBooks

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:books) do
    [
      primary_key()
      column(:title, :string, limit = 100)
      column(:author, :string, limit = 100)
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

The DSL is pretty readable: in the `up` function we call `create_table` and pass an array of columns: a primary key, a `title` column and an `author` column (both strings have a max length of 100). We also add two indices (one on the `title` and the other on the `author` columns). As for the `down` method, it invokes the `drop_table` function to remove the table.

#### Running the migration

We can see what SearchLight knows about our migrations with the `SearchLight.Migrations.status` command:

```julia
julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                 CreateTableBooks: DOWN |
| 1 | 2020020909574048_create_table_books.jl |
```

So our migration is in the `down` state – meaning that its `up` method has not been run. We can easily fix this:

```julia
julia> SearchLight.Migrations.last_up()
[ Info: Executed migration CreateTableBooks up
```

If we recheck the status, the migration is up:

```julia
julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2020020909574048_create_table_books.jl |
```

Our table is ready!

#### Defining the model

Now it's time to edit our model file at `app/resources/books/Books.jl`. Another convention in SearchLight is that we're using the pluralized name (`Books`) for the module – because it's for managing multiple books. And within it we define a type (a `mutable struct`), called `Book` – which represents an item (a single book) which maps to a row in the underlying database.

Edit the `Books.jl` file to make it look like this:

```julia
# Books.jl
module Books

using SearchLight

export Book

mutable struct Book <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String

  ### FIELDS
  id::DbId
  title::String
  author::String
end

Book(;
    ### FIELDS
    id = DbId(),
    title = "",
    author = ""
  ) = Book("books", "id", id, title, author)

end
```

We defined a `mutable struct` which matches our previous `Book` type except that it has a few special fields used internally by SearchLight: the fields starting with an underscore  reference the table name and the name of the primary key column. We also define a keyword constructor as SearchLight needs it.

#### Using our model

To make things more interesting, we should import our current books into the database. Add this function to the `Books.jl` module, under the `Book()` constructor definition (just above the module's closing `end`):

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

#### Auto-loading the DB configuration

Now, to try things out. Genie takes care of loading all our resource files for us when we load the app. To do this, Genie comes with a special file called an initializer, which automatically loads the database configuration and sets up SearchLight. Check `config/initializers/searchlight.jl`. It should look like this:

```julia
using SearchLight

SearchLight.Configuration.load()
eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
SearchLight.connect()
```

---
**Heads up!**

All the `*.jl` files placed into the `config/initializers/` folder are automatically included by Genie upon starting the Genie app. They are included early (upon initialisation), before the controllers, models, views, are loaded.

---

#### Trying it out

Now it's time to restart our REPL session and test our app. Close the Julia REPL session to exit to the OS command line and run:

```bash
$ bin/repl
```

The `repl` executable script placed within the app's `bin/` folder starts a new Julia REPL session and loads the applications' environment. Everything should be automatically loaded now, DB configuration included - so we can invoke the previously defined `seed` function to insert the books:

```julia
julia> using Books

julia> Books.seed()
```

There should be a list of queries showing how the data is inserted in the DB:

```julia
julia> Books.seed()
[ Info: INSERT  INTO books ("title", "author") VALUES ('The Best We Could Do', 'Thi Bui')
[ Info: INSERT  INTO books ("title", "author") VALUES ('Evicted: Poverty and Profit in the American City', 'Matthew Desmond')
# output truncated
```

If you want to make sure all went right (although trust me, it did, otherwise SearchLight would've thrown an `Exception`!), just ask SearchLight to retrieve them:

```julia
julia> using SearchLight

julia> all(Book)
[ Info: 2020-02-09 13:29:32 SELECT "books"."id" AS "books_id", "books"."title" AS "books_title", "books"."author" AS "books_author" FROM "books" ORDER BY books.id ASC

5-element Array{Book,1}:
 Book
| KEY            | VALUE                |
|----------------|----------------------|
| author::String | Thi Bui              |
| id::DbId       | 1                    |
| title::String  | The Best We Could Do |

 Book
| KEY            | VALUE                                            |
|----------------|--------------------------------------------------|
| author::String | Matthew Desmond                                  |
| id::DbId       | 2                                                |
| title::String  | Evicted: Poverty and Profit in the American City |

# output truncated
```

The `SearchLight.all` method returns all the `Book` items from the database.

All good!

The next thing we need to do is to update our controller to use the model. Make sure that `app/resources/books/BooksController.jl` reads like this:

```julia
# BooksController.jl
module BooksController

using Genie.Renderer.Html, SearchLight, Books

function billgatesbooks()
  html(:books, :billgatesbooks, books = all(Book))
end

module API

using ..BooksController
using Genie.Renderer.Json, SearchLight, Books

function billgatesbooks()
  json(:books, :billgatesbooks, books = all(Book))
end

end

end
```

Our JSON view needs a bit of tweaking too:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in books]
```

Now if we just start the server we'll be able to see the list of books served from the database:

```julia
# Start the server
julia> up()
```

The `up` method starts up the web server and takes us back to the interactive Julia REPL prompt.

Now, if, for example, we navigate to <http://localhost:8000/api/v1/bgbooks>, the output should match the following JSON document:

```json
{
  "Bill's Gates list of recommended books": [
    {
      "author": "Thi Bui",
      "title": "The Best We Could Do"
    },
    {
      "author": "Matthew Desmond",
      "title": "Evicted: Poverty and Profit in the American City"
    },
    {
      "author": "Eddie Izzard",
      "title": "Believe Me: A Memoir of Love, Death, and Jazz Chickens"
    },
    {
      "author": "Viet Thanh Nguyen",
      "title": "The Sympathizer!"
    },
    {
      "author": "Vaclav Smil",
      "title": "Energy and Civilization, A History"
    }
  ]
}
```

Let's add a new book to see how it works. We'll create a new `Book` item and persist it using the `SearchLight.save!` method:

```julia
julia> newbook = Book(title = "Leonardo da Vinci", author = "Walter Isaacson")

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | NULL              |
| title::String  | Leonardo da Vinci |


julia> save!(newbook)

[ Info: INSERT  INTO books ("title", "author") VALUES ('Leonardo da Vinci', 'Walter Isaacson')
[ Info: ; SELECT CASE WHEN last_insert_rowid() = 0 THEN -1 ELSE last_insert_rowid() END AS id
[ Info: SELECT "books"."id" AS "books_id", "books"."title" AS "books_title", "books"."author" AS "books_author" FROM "books" WHERE "id" = 6 ORDER BY books.id ASC

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | 6                 |
| title::String  | Leonardo da Vinci |
```

Calling the `save!` method, SearchLight has persisted the object in the database and then retrieved it and returned it (notice the updated `id::DbId` field).

The same `save!` operation can be written as a one-liner:

```julia
julia> Book(title = "Leonardo da Vinci", author = "Walter Isaacson") |> save!
```

---
**HEADS UP**

If you also run the one-liner `save!` example, it will add the same book again. No problem, but if you want to remove it, you can use the `delete` method:

```julia
julia> delete(ans)
[ Info: DELETE FROM books WHERE id = '7'

Book
| KEY            | VALUE             |
|----------------|-------------------|
| author::String | Walter Isaacson   |
| id::DbId       | NULL              |
| title::String  | Leonardo da Vinci |
```

---

If you reload the page at <http://localhost:8000/bgbooks> the new book should show up.

```json
{
  "Bill's Gates list of recommended books": [
    {
      "author": "Thi Bui",
      "title": "The Best We Could Do"
    },
    {
      "author": "Matthew Desmond",
      "title": "Evicted: Poverty and Profit in the American City"
    },
    {
      "author": "Eddie Izzard",
      "title": "Believe Me: A Memoir of Love, Death, and Jazz Chickens"
    },
    {
      "author": "Viet Thanh Nguyen",
      "title": "The Sympathizer!"
    },
    {
      "author": "Vaclav Smil",
      "title": "Energy and Civilization, A History"
    },
    {
      "author": "Walter Isaacson",
      "title": "Leonardo da Vinci"
    }
  ]
}
```

---
**PRO TIP**

SearchLight exposes two similar data persistence methods: `save!` and `save`. They both perform the same action (persisting the object to the database), but `save` will return a `Bool` `true` to indicate that the operation was successful or a `Bool` `false` to indicate that the operation has failed. While the `save!` variant will return the persisted object upon success or will throw an exception on failure.

---

## Congratulations

You have successfully finished the first part of the step by step walkthrough - you now master the Genie basics, allowing you to set up a new app, register routes, add resources (controllers, models, and views), add database support, version the database schema with migrations, and execute basic queries with SearchLight!

In the next part we'll look at more advanced topics like handling forms and file uploads, templates rendering, interactivity and more.
