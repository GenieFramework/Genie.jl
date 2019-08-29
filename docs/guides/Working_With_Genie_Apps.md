# Working with Genie apps (projects)

Working with Genie in an interactive environment can be useful – but usually we want to persist our application and reload it between sessions.
One way to achieve that is to save it as an IJulia notebook and rerun the cells. However, you can get the most of Genie by working with Genie apps.
A Genie app is an MVC web application which promotes the convention-over-configuration principle. By working with a few predefined files, within the Genie app structure, the framework can lift a lot of weight and massively improve development productivity. This includes automatic module loading and reloading, dedicated configuration files, logging, environments, code generators, and more.

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
* start the web server on the default port (8000)

At this point you can confirm that everything worked as expected by visiting <http://localhost:8000> in your favourite web browser.
You should see Genie's welcome page.

Next, let's add a new route. This time we need to append it to the dedicated `routes.jl` file. Edit `/path/to/MyGenieApp/routes.jl` in your favourite editor or run the next snippet (making sure you are in the app's directory):

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

Visit <http://localhost:8000/hello> for a warm welcome!

## Working with resources

Adding your code to the `routes.jl` file or placing it into the `lib/` folder works great for small projects, where you want to quickly publish some features on the web. But for larger projects we're better off using Genie's MVC structure. By employing the Module-View-Controller design pattern we can break our code in modules with clear responsibilities. Modular code is easier to write, test and maintain.

A Genie app is structured around the concept of "resources". A resource represents a business entity (something like a user, or a product, or an account) and maps to a bundle of files (controller, model, views, etc).

Resources live under the `app/resources/` folder. For example, if we have a web app about "books", a "books/" folder would be placed in `app/resources/` and would contain all the files for publishing books on the web.

---
**HEADS UP**

When creating a default Genie app (micro-framework) the `app/` folder might be missing. This will be automatically created the first time you add a resource via Genie's generators.

---

## Using Controllers

Controllers are used to orchestrate interactions between client requests, models (which handle DB access), and views (which are responsible with rendering the responses for the clients). In a standard workflow, a `route` points to a method in the controller – which is charged with building and sending the response over the network.

Let's add a "books" controller. Genie comes with handy generators and one of them is for creating new controllers:

### Generate the Controller

Let's generate our `BooksController`:

```julia
julia> Genie.newcontroller("Books")
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
  "
  <h1>Bill Gates' list of recommended books</h1>
  <ul>
    $(["<li>$(book.title) by $(book.author)" for book in BillGatesBooks]...)
  </ul>
  "
end

end
```

Our controller is just a plain Julia module where we define a `Book` type and set up an array of book objects. We then defined a function, `billgatesbooks`, which returns an HTML string, with a heading an an unordered list of all the books. We used an array comprehension to iterate over each book and render it in a `<li>` element. The elements of the array are then concatenated using the `...` operator.
The plan is to map this function to a route and expose it on the internet.

#### Checkpoint

Before exposing it on the web, we can test it in the REPL:

```julia
julia> using BooksController

julia> BooksController.billgatesbooks()
"\n    <h1>Bill Gates' list of recommended books</h1>\n    <ul>\n      <li>The Best We Could Do by Thi Bui<li>Evicted: Poverty and Profit in the American City by Matthew Desmond<li>Believe Me: A Memoir of Love, Death, and Jazz Chickens by Eddie Izzard<li>The Sympathizer by Viet Thanh Nguyen<li>Energy and Civilization, A History by Vaclav Smil\n    </ul>\n  "
```

Make sure it works as expected - we should get the HTML string previously described.

### Setup the route

Now, let's expose our `billgatesbooks` method on the web. We need to add a new `route` which points to it. Add these to the `routes.jl` file (feel free to keep or delete what's already in it):

```julia
# routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```

That's all! If you now visit `http://localhost:8000/bgbooks` you'll see Bill Gates' list of recommended books.

### Adding views

However, putting HTML into the controllers is a bad idea: that should stay in the view files. Let's refactor our code to use views.

The views used for rendering a resource should be placed inside a `views/` folder, within that resource's own folder.
So in our case, we will add an `app/resources/books/views/` folder. Just go ahead and do it, Genie does not provide a generator for this simple task:

```julia
julia> mkdir("app/resources/books/views")
```

### Naming views

Usually each controller method will have its own rendering logic – hence, its own view file. Thus, it's a good practice to name the view files just like the methods, so we can keep track of where they're used.

At the moment, Genie supports HTML and Markdown view files, as well as plain Julia. Their type is identified by file extension so that's an important part.
The HTML views use a `.jl.html` extension while the Markdown files go with `.jl.md` and the Julia ones `flax.jl`.

### HTML views

All right then, let's add our first view file for the `BooksController.billgatesbooks` method. Let's add an HTML view. With Julia:

```julia
julia> touch("app/resources/books/views/billgatesbooks.jl.html")
```

Genie supports a special type of dynamic HTML view, where we can embed Julia code. These are high performance compiled views. They are _not_ parsed as strings: instead, **the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file**.
Hence, the first time you load a view or after you change one, you might notice a certain delay – it's the time needed to generate and compile the view.
On next runs (especially in production) it's going to be blazing fast!

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

As you can see, it's just plain HTML with embedded Julia. We can add Julia code by using the `<% ... %>` code block tags – these should be used for more complex, multiline expressions.
Or by using plain string interpolation with `$(...)` – for simple values outputting.

It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, your Julia view code _must return a string_ as the result, so that the output of your computation comes up on the page.

Genie provides a series of helpers, like the above `@foreach` macro.

Also, very important, please notice the `@vars` macro. This is used to access variables which are passed from the controller into the view.
We'll see how to use this right now.

### Rendering views

We now need to refactor our controller to use the view, passing in the expected variables. We will use the `html` method which renders and outputs the response as HTML (you've seen its `json` counterpart earlier).
Update the definition of the `billgatesbooks` function to be as follows:

```julia
# BooksController.jl
using Genie.Renderer

function billgatesbooks()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end
```

First, notice that we needed to add `Genie.Renderer` as a dependency, to get access to the `html` method. As for the `html` method, it takes as its arguments:

* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file);
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out since there's only one file with this name;
* and finally, we pass the values we want to expose in the view, as keyword arguments. In this scenario, the `books` keyword argument – which will be available in the view file under `@vars(:books)`.

That's it – our refactored app should be ready!

### Markdown views

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

We can edit it. For example, add this right under the `<body>` tag:

```html
<h1>Welcome to top books</h1>
```

If you reload the page at <http://localhost:8000/bgbooks> you will see the new heading.

But we don't have to stick to the default; we can add additional layouts. Let's suppose that we have for example an admin area which should have a completely different theme.
We can add a dedicated layout for that:

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

Finally, we must instruct our `BooksController` to use it. The `html` function takes a keyword argument `layout`, for the layout.
Update the `billgatesbooks` function to look like this:

```julia
# BooksController.jl
function billgatesbooks()
  html(:books, :billgatesbooks, layout = :admin, books = BillGatesBooks)
end
```

Reload the page and you'll see the new heading.

#### The `@yield` instruction

There is a special instruction in the layouts: `@yield`. It outputs the content of the view. So basically where this macro is present, Genie will output the HTML resulting from rendering the view by executing the action in the controller.

### Rendering JSON views

A common use case for web apps is to serve as backends for RESTful APIs. For this cases, JSON is the preferred data format. You'll be happy to hear that Genie has built in support for JSON responses. Let's add an endpoint for our API – which will render Bill Gates' books as JSON.

We can start in the `routes.jl` file, by appending this

```julia
route("/api/v1/bgbooks", BooksController.API.billgatesbooks)
```

Next, in `BooksController.jl`, append the extra logic at the end. The whole file should look like this:

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
  html(:books, :billgatesbooks, layout = :admin, books = BillGatesBooks)
end


module API

using ..BooksController
import JSON

function billgatesbooks()
  JSON.json(BooksController.BillGatesBooks)
end

end

end
```

We nested an API module within the BooksController module, where we defined another `billgatesbooks` function which outputs a JSON by using the JSON package. Keep in mind that you're free to organize the code as you see fit – not necessarily like this. It's just one way to do it.

If you go to `http://localhost:8000/api/v1/bgbooks` it should already work.

Not a bad start, but we can do better. First, the MIME type of the response is not right. By default Genie will return `text/html`.
We need `application/json`. That's easy to fix though, we can just use Genie's `json` method. The `API` submodule should look like this:

```julia
module API

using ..BooksController
using Genie.Renderer
import JSON

function billgatesbooks()
  json(BooksController.BillGatesBooks)
end

end
```

Notice that we are `using Genie.Renderer` to access Genie's own `json` method. If you reload the "page", you'll get a proper JSON response. Great!

#### JSON views

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone as any changes in the data will break the client's integrations. The solution is to, again, use views, to fully control how we render our data – and decouple the data structure from its rendering on the web.

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

## Accessing databases with SeachLight models

You can get the most out of Genie by pairing it with its seamless ORM layer, SearchLight. SearchLight, a native Julia ORM, provides excellent support for working with relational databases. The Genie + SearchLight combo can be used to productively develop CRUD based apps.

---
**HEADS UP**

CRUD stands for Create-Read-Update-Delete and describes the data workflow in the apps.

---

SearchLight represents the "M" part in Genie's MVC architecture (thus, the Model layer).

Let's begin by adding SearchLight to our Genie app. All Genie apps manage their dependencies in their own environment, through their `Project.toml` and `Manifest.toml` files.

So we need to make sure that we're in `pkg> ` shell mode first (which is entered by typing `]` in julian mode, ie: `julia>]`).
The cursor should change to `(MyGenieApp) pkg>`.

Next, we add `SearchLight`:

```julia
(MyGenieApp) pkg> add SearchLight#master
```

### Setup the database connection

Genie is designed to seamlessly integrate with SearchLight and provides access to various database oriented generators. First we need to tell Genie/SearchLight how to connect to the database. Let's use them to set up our database support. Run this in the Genie/Julia REPL:

```julia
julia> Genie.Generator.db_support()
```

The command will add a `db/` folder within the root of the app. What we're looking for is the `db/connection.yml` file. Let's edit it. Make the file to look like this:

```yaml
env: dev

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```

This instructs SearchLight to run in the `dev` environment, using SQLite for the adapter (backend) and a database stored at `db/books.sqlite`. We could pass extra configuration options in the `config` object but for now we don't need anything else.

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

Awesome! If all went well you should have a `books.sqlite` database in the `db/` folder. We got a SQLite database handle.

### Managing the database schema with `SearchLight` migrations

Database migrations provide a way to reliably, consistently and repeatedly apply (and undo) schema transformations. They are specialised scripts for adding, removing and altering DB tables – these scripts are placed under version control and are managed by a dedicated system which knows which scripts have been run and which not, and is able to run them in the correct order.

SearchLight needs its own DB table to keep track of the state of the migrations so let's set it up:

```julia
julia> SearchLight.init()
[info]: SQL QUERY: CREATE TABLE `schema_migrations` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  )
[info]: Created table schema_migrations
```

This command creates sets up our database with the needed table in order to manage migrations.

### Creating our Book model

SearchLight, just like Genie, uses the convention-over-configuration design pattern. It prefers for things to be setup in a certain way and provides sensible defaults, versus having to define everything in extensive configuration files. And fortunately, we don't even have to remember what these conventions are, as SearchLight also comes with an extensive set of generators.

Lets ask SearchLight to create our model:

```julia
julia> SearchLight.Generator.newresource("Book")

[info]: New model created at /path/to/MyGenieApp/app/resources/books/Books.jl
[info]: New table migration created at /path/to/MyGenieApp/db/migrations/2019081212100662_create_table_books.jl
[info]: New validator created at /path/to/MyGenieApp/app/resources/books/BooksValidator.jl
[info]: New unit test created at /path/to/MyGenieApp/test/unit/books_test.jl
```

SearchLight has created the `Books.jl` model, the `*_create_table_books.jl` migration file, the `BooksValidator.jl` model validator and the `books_test.jl` test file. The `*_create_table_books.jl` file will be named differently for you as the first part of the name is the timestamp. The timestamp guarantees that names are unique and name clashes are avoided.

#### Writing the table migration

Lets begin by writing the migration to create our books table. SearchLight provides a powerful DSL for writing migrations.
Each migration file needs to define two methods: `up` which applies the changes – and `down` which undoes the effects of the `up` method.
So in our `up` method we want to create the table – and in `down` we want to drop the table.

The naming convention for tables in SearchLight is that the table name should be pluralized (`books`) – because a table contains multiple books.
But don't worry, the migration file should already be pre-populated with the correct table name.

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
| 1 | 2019081212100662_create_table_books.jl |
```

So our migration is in the `down` state – meaning that its `up` method has not been run. We can easily fix this:

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
| 1 | 2019081212100662_create_table_books.jl |
```

Our table is ready!

#### Defining the model

Now it's time to edit our model file at `app/resources/books/Books.jl`. Another convention in SearchLight is that we're using the pluralized name (`Books`) for the module – because it's for managing multiple books. And within it we define a type, called `Book` – which represents an item (a single book) and maps to a row in the underlying database.

Do not let the large file intimidate you - the commented out code readily makes available some of the most important features of the model type, but we can ignore all that for now and simply delete it and replace it with this code. The `Books.jl` file should look like this:

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

We defined a `mutable struct` which matches our previous `Book` type except that it has a few special fields used by SearchLight: the fields starting with an underscore which reference the table name and the name of the primary key column. We also define a keyword constructor as SearchLight needs it.

#### Using our model

To make things more interesting, we should import our current books into the database. Add this function to the `Books.jl` module, under the `Book()` constructor definition:

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

Now, to try things out. Genie takes care of loading all our resource files for us when we load the app. To do this, Genie comes with a special file called an initializer, which automatically loads the database configuration and sets up SearchLight. Edit `config/initializers/searchlight.jl` and uncomment the code. It should look like this:

```julia
using SearchLight, SearchLight.QueryBuilder

SearchLight.Configuration.load()

if SearchLight.config.db_config_settings["adapter"] !== nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end
```

##### Heads up!

All the `.jl` files placed into the `config/initializers/` folder are automatically included by Genie upon starting the Genie app. They are included early (upon initialisation), before the controllers, models, views, are loaded.

#### Trying it out!

Now it's time to restart our REPL session and test our app. Exit to the OS command line and run:

```bash
$ bin/repl
```

Everything should be loaded now, DB configuration included - so we can invoke the previously defined `seed` function to insert the books:

```julia
julia> using Books

julia> Books.seed()
```

There should be a list of queries showing how the data is inserted in the DB. If you want to make sure, just ask SearchLight to retrieve them:

```julia
julia> using SearchLight

julia> SearchLight.all(Book)

5-element Array{Book,1}:
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

The next thing we need to do is to update our controller to use the model. Make sure that `app/resources/books/BooksController.jl` reads like this:

```julia
# BooksController.jl
module BooksController

using Genie.Renderer, SearchLight, Books

function billgatesbooks()
  html(:books, :billgatesbooks, books = SearchLight.all(Book))
end

module API

using ..BooksController
using Genie.Renderer
using SearchLight, Books

function billgatesbooks()
  json(:books, :billgatesbooks, books = SearchLight.all(Book))
end

end

end
```

And finally, our JSON view needs a bit of tweaking too:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in @vars(:books)]
```

Now if we just start the server we'll see the list of books served from the database, at <http://localhost:8000/api/v1/bgbooks>

```julia
julia> startup()
```

Let's add a new book to see how it works:

```julia
julia> newbook = Book(title = "Leonardo da Vinci", author = "Walter Isaacson")

julia> SearchLight.save!(newbook)
```

or as a one-liner:
```julia
julia> Book(title = "Leonardo da Vinci", author = "Walter Isaacson") |> SearchLight.save!
```

If you reload the page at <http://localhost:8000/bgbooks> the new book should show up.

---

## Congratulations!

You have successfully finished the first part of the step by step walkthrough - you now master the Genie basics, allowing you to set up a new app, register routes, add resources (controllers, models, and views), add database support, version the database schema with migrations, and execute basic queries with SearchLight!

In the next part we'll look at more advanced topics like handling forms and file uploads, templates rendering, interactivity and more.
