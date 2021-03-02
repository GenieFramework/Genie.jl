Here is a complete walk-through of developing a feature rich MVC app with Genie, including both user facing web pages, a REST API endpoint, and user authentication. 

---

## Getting started - creating the app

First, let's create a new Genie MVC app. We'll use Genie's app generator, so first let's make sure we have Genie installed.

Let's start a Julia REPL and add Genie:

```julia
pkg> add Genie # press ] from julia> prompt to enter Pkg mode
```

Now, to create the app:

```julia
julia> Genie.newapp_mvc("Watch tonight")
```

Genie will bootstrap a new application for us, creating the necessary files and installing dependencies. As we're creating a MVC app, Genie will offer to install support for SearchLight, Genie's ORM, and will ask what database backend we'll want to use:

```shell
Please choose the DB backend you want to use:
1. SQLite
2. MySQL
3. PostgreSQL
Input 1, 2 or 3 and press ENTER to confirm
```

We'll use SQLite in this demo, so let's press "1". Once the process is completed, Genie will start the new application at <http://127.0.0.1:8000>. We can open it in the browser to see the default Genie home page.

### How does this work?

Genie uses the concept of routes and routing in order to map a URL to a request handler (a Julia function) within the app. If we edit the `routes.jl` file we will see that is has defined a `route` with for requests at `/` will display a static file called `welcome.html` (and which can be found in the `public/` folder):

```julia
route("/") do
  serve_static_file("welcome.html")
end
```

## Connecting to the database

In order to configure the database connection we need to edit the `db/connection.yml` file, to make it look like this:

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/netflix_catalog.sqlite
  config:
```

Now let's manually load the database configuration:

```julia
julia> include(joinpath("config", "initializers", "searchlight.jl")
SQLite.DB("db/netflix_catalog.sqlite")
```

## Creating a Movie resource

A resource is a business entity made available through the application via a URL. In a Genie MVC app it also represents a bundle of Model, View, and Controller files - as well as additional files including a migration file for modifying the database, a test file, and a model data validator.

In the REPL run:

```julia
julia> Genie.newresource("movie")
```

### Creating the DB table using the database migration

We need to edit the migrations file we just created in `db/migrations/`. Look for a file that ends in `_create_table_movies.jl` and make it look like this:

```julia
module CreateTableMovies

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:movies) do
    [
      primary_key()
      column(:type, :string, limit = 10)
      column(:title, :string, limit = 100)
      column(:directors, :string, limit = 100)
      column(:actors, :string, limit = 250)
      column(:country, :string, limit = 100)
      column(:year, :integer, limit = 4)
      column(:rating, :string, limit = 10)
      column(:categories, :string, limit = 100)
      column(:description, :string, limit = 1_000)
    ]
  end

  add_index(:movies, :title)
  add_index(:movies, :actors)
  add_index(:movies, :categories)
  add_index(:movies, :description)
end

function down()
  drop_table(:movies)
end

end
```

#### Creating the migrations table

In order to be able to manage the app's migrations, we need to create the DB table used by SearchLight's migration system. This is easily done using SearchLight's generators:

```julia
julia> SearchLight.Migration.create_migrations_table()
```

### Running the migration

We can now check the status of the migrations:

```julia
julia> SearchLight.Migration.status()
```

And run the last migration UP:

```julia
julia> SearchLight.Migration.last_up()
```

## Creating the Movie model

Now that we have the database table, we need to create the model file which allows us manage the data. The file has already been created for us in `app/resources/movies/Movies.jl`. Edit it and make it look like this:

```julia
module Movies

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Movie

@kwdef mutable struct Movie <: AbstractModel
  id::DbId = DbId()
  type::String = "Movie"
  title::String = ""
  directors::String = ""
  actors::String = ""
  country::String = ""
  year::Int = 0
  rating::String = ""
  categories::String = ""
  description::String = ""
end

end
```

### Interacting with the movies data

Once our model is created, we can interact with the database:

```julia
julia> using Movies

julia> m = Movie(title = "Test movie", actors = "John Doe, Jane Doe")
```

We can check if our movie object is persisted (saved to the db):

```julia
julia> ispersisted(m)
false
```

And we can save it:

```julia
julia> save(m)
true
```

Now we can run various methods against our data:

```julia
julia> count(Movie)

julia> all(Movie)
```

### Seeding the data

We're now ready to load the movie data into our database - we'll use a short seeding script. First make sure to place the CVS file into the `/db/seeds/` folder. Create the seeds file:

```julia
julia> touch(joinpath("db", "seeds", "seed_movies.jl"))
```

And edit it to look like this:

```julia
using SearchLight, Movies
using CSV

Base.convert(::Type{String}, _::Missing) = ""
Base.convert(::Type{Int}, _::Missing) = 0
Base.convert(::Type{Int}, s::String) = parse(Int, s)

function seed()
  for row in CSV.Rows(joinpath(@__DIR__, "netflix_titles.csv"), limit = 1_000)
    m = Movie()

    m.type = row.type
    m.title = row.title
    m.directors = row.director
    m.actors = row.cast
    m.country = row.country
    m.year = row.release_year
    m.rating = row.rating
    m.categories = row.listed_in
    m.description = row.description

    save(m)
  end
end
```

Add CSV.jl as a dependency of the project:

```julia
pkg> add CSV
```

And now to seed the db:

```julia
julia> include(joinpath("db", "seeds", "seed_movies.jl"))
julia> seed()
```

## Setting up the web page

We'll start by adding the route to our handler function. Let's open the `routes.jl` file and add:

```julia
# routes.jl
using MoviesController

route("/movies", MoviesController.index)
```

This route declares that the `/movies` URL will be handled by the `MoviesController.index` index function. Let's put it in by editing `/app/resources/movies/MoviesController.jl`:

```julia
module MoviesController

function index()
  "Welcome to movies list!"
end

end
```

If we navigate to <http://127.0.0.1:8000/movies> we should see the welcome.

Let's make this more useful though and display a random movie upon landing here:

```julia
module MoviesController

using Genie.Renderer.Html, SearchLight, Movies

function index()
  html(:movies, :index, movies = rand(Movie))
end

end
```

The index function renders the `/app/resources/movies/views/index.jl.html` view file as HTML, passing it a random movie into the `movies` instance. Since we don't have the view file yet, let's add it:

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "index.jl.html"))
```

Make it look like this:

```html
<h1 class="display-1 text-center">Watch tonight</h1>
<%
if ! isempty(movies)
  @foreach(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>
```

Now to create the `_movie.jl.html` partial file to render a movie object:

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "_movie.jl.html"))
```

Edit it like this:

```html
<div class="container" style="margin-top: 40px;">
  <h3><% movie.title %></h3>

  <div>
    <small class="badge bg-primary"><% movie.year %></small> |
    <small class="badge bg-light text-dark"><% movie.type %></small> |
    <small class="badge bg-dark"><% movie.rating %></small>
  </div>

  <h4><% movie.description %></h4>

  <div><strong>Directed by: </strong><% movie.directors %></div>
  <div><strong>Cast: </strong><% movie.actors %></div>
  <div><strong>Country: </strong><% movie.country %></div>
  <div><strong>Categories: </strong><% movie.categories %></div>
</div>
```

And finally, the `_no_results.jl.html` partial:

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "_no_results.jl.html"))
```

Which must look like this:

```html
<h4 class="container">
  Sorry, no results were found for "$(@params(:search_movies))"
</h4>
```

### Using the layout file

Let's make the web page nicer by loading the Twitter Bootstrap CSS library. As it will be used across all the pages of the website, we'll load it in the main layout file. Edit `/app/layouts/app.jl.html` to look like this:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Genie :: The Highly Productive Julia Web Framework</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BmbxuPwQa2lc/FVzBcNJ7UAyJxM6wuqIj61tLrc4wSX0szH/Ev+nYRRuWlolflfl" crossorigin="anonymous">
  </head>
  <body>
    <div class="container">
    <%
      @yield
    %>
    </div>
  </body>
</html>
```

## Adding the search feature

Now that we can display titles, it's time to implement the search feature. We'll add a search form onto our page. Edit `/app/resources/movies/views/index.jl.html` to look like this:

```html
<h1 class="display-1 text-center">Watch tonight</h1>

<div class="container" style="margin-top: 40px;">
  <form action="$( linkto(:search_movies) )">
    <input class="form-control form-control-lg" type="search" name="search_movies" placeholder="Search for movies and TV shows" />
  </form>
</div>

<%
if ! isempty(movies)
  @foreach(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>
```

We have added a HTML `<form>` which submits a query term over GET.

Next, add the route:

```julia
route("/movies/search", MoviesController.search, named = :search_movies)
```

And the `MoviesController.search` function after updating the `using` section:

```julia
using Genie, Genie.Renderer, Genie.Renderer.Html, SearchLight, Movies

function search()
  isempty(strip(@params(:search_movies))) && redirect(:get_movies)

  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * @params(:search_movies) * '%'], 4)))

  html(:movies, :index, movies = movies)
end
```

Time to check our progress: <http://127.0.0.1:8000/movies>

## Building the REST API

Let's start by adding a new route for the API search:

```julia
route("/movies/search_api", MoviesController.search_api)
```

With the corresponding `search_api` method in the `MoviesController` model:

```julia
using Genie, Genie.Renderer, Genie.Renderer.Html, SearchLight, Movies, Genie.Renderer.Json

function search_api()
  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * @params(:search_movies) * '%'], 4)))

  json(Dict("movies" => movies))
end
```

## Bonus

Genie makes it easy to add database backed authentication for restricted area of a website, by using the `GenieAuthentication` plugin. Start by adding package:

```julia
pkg> add GenieAuthentication

julia> using GenieAuthentication
```

Now, to install the plugin files:

```julia
julia> GenieAuthentication.install(@__DIR__)
```

The plugin has created a create table migration that we need to run UP:

```julia
julia> SearchLight.Migration.up("CreateTableUsers")
```

Let's generate an Admin controller that we'll want to protect by login:

```julia
julia> Genie.Generator.newcontroller("Admin", pluralize = false)
```

And manually load the plugin file:

```julia
include(joinpath("plugins", "genie_authentication.jl"))
```

Time to create an admin user for logging in:

```julia
julia> u = User(email = "admin@admin", name = "Admin", password = Users.hash_password("admin"), username = "admin")

julia> save!(u)
```

We'll also need a route for the admin area:

```julia
using AdminController

route("/admin/movies", AdminController.index, named = :get_home)
```

And finally, the controller code:

```julia
module AdminController

using GenieAuthentication, Genie.Renderer, Genie.Exceptions, Genie.Renderer.Html

before() = authenticated() || throw(ExceptionalResponse(redirect(:show_login)))

function index()
  h1("Welcome Admin") |> html
end

end
```

If we navigate to `http://127.0.0.1:8000/admin/movies` we'll be asked to logged in. Using `admin` for the user and `admin` for the password will allow us to access the password protected section.

