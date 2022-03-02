### A Pluto.jl notebook ###
# v0.18.0

using Markdown
using InteractiveUtils

# ╔═╡ bc4234b8-67d4-4844-a907-d45a4649db8b
# hideall

using Genie

# ╔═╡ 9ab99155-0cdf-4b13-9719-61a6608bedc7
# hideall 

using SearchLight

# ╔═╡ bd0482b9-ebec-425d-99c0-e31e5af2e498
using CSV


# ╔═╡ 476096fa-2ff7-11ec-3426-f77a9804eb1a
md"""
# Developing MVC web applications
"""

# ╔═╡ 63864c9f-42e6-4cdf-8b67-be0f4f00a51e
md"""
Here is a complete walk-through of developing a feature rich MVC app with Genie, including both user facing web pages, a REST API endpoint, and user authentication. You can see and clone the full app here: <https://github.com/essenciary/genie-watch-tonight>
"""

# ╔═╡ 189c8d2a-30b1-11ec-0e97-b7704e8c2588
md"""
### Adding Genie
"""

# ╔═╡ f220c2b5-99c4-481e-9d09-334934d964b2
md"""

```julia

julia> using Pkg

julia> Pkg.add("Genie")
```
"""

# ╔═╡ 374b0835-316e-4737-8610-92a6febfd986
md"""
## Getting started - creating the app
First, let's create a new Genie MVC app. We'll use Genie's app generator, so first let's make sure we have Genie installed.

Let's start a Julia REPL and add Genie:
"""

# ╔═╡ a608794b-cfaf-4e41-83e7-7f9f700b3d1a
md"""
Now, to create the app:

"""

# ╔═╡ 2e4cd23d-472b-4161-a592-9f92b0f4b3b1
md"""

```julia
julia> using Genie

julia> Genie.newapp_mvc("Watch tonight", dbadapter= :SQLite)
```
"""

# ╔═╡ eebc2a27-ac29-4f70-998c-d2a5be7a29ce
# hideall

Genie.newapp_mvc("Watch tonight", dbadapter= :SQLite)

# ╔═╡ 65ea2335-4d7f-4e48-9aef-453141d3551c
md"""

or you can create a Genie App and pick your choice of db at runtime: 

```julia
Genie.newapp_mvc("Watch tonight")
```

If you however don't pass `dbadapter` in `newapp_mvc` generator you will be presented with following instructions of selecting the adapter.
"""

# ╔═╡ 89f2cc70-c656-4aa9-8ea6-ca739871e0d6
md"""
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


Now, we can stop the server by hitting <ctrl+d> (windows/linux) or <cmd+d> (macos). You can restart the server by

```shell
$ cd Watchtonight
$ bin/server
```

However, for this tutorial we Genie's interactive mode:

```shell
$ cd Watchtonight
$ bin/repl
```
"""

# ╔═╡ 7a63f66a-de61-4a1f-a73a-577cbbaf9622
md"""

## Connecting to the database

In order to configure the database connection we need to edit the `db/connection.yml` file, to make it look like this:

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/netflix_catalog.sqlite
  config:
```

"""

# ╔═╡ 8cf3615d-a101-4c50-926d-172703c2ee70
# hideall

begin
	db_connection = true;
	chmod("$(dirname(pwd()))/Watchtonight/db/connection.yml", 0o777);
end;

# ╔═╡ bb0796e4-e5ad-4d5d-b59c-9af9bfec6eb7
# hideall

begin
	db_connection;
	write("$(dirname(pwd()))/Watchtonight/db/connection.yml", """env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/netflix_catalog.sqlite
  config:""");
end;

# ╔═╡ 17df041b-e6c2-4719-a81d-a8f6e2f1bc01
md"""
Now let's manually load the database configuration:
"""

# ╔═╡ 871252c0-ad15-44d6-ac5e-572eebc2577e
md"""
```julia
julia> include(joinpath("config", "initializers", "searchlight.jl"))
SQLite.DB("db/netflix_catalog.sqlite")
```
"""

# ╔═╡ 9ac74156-4af7-48d8-989b-38f65ea3c411
# hideall

begin
	db_connection;
	searchlight_path = joinpath("$(dirname(pwd()))/Watchtonight/config", "initializers", "searchlight.jl");
end;

# ╔═╡ 772f1056-eb1a-4a78-bd16-52578a0fc5de
# hideall

begin
	db_connection;
	include(searchlight_path);
end;

# ╔═╡ 0612248e-2ca1-4643-879a-21b13bd4906f
md"""
## Creating a Movie resource

A resource is a business entity made available through the application via a URL. In a Genie MVC app it also represents a bundle of Model, View, and Controller files - as well as additional files including a migration file for modifying the database, a test file, and a model data validator.

In the julia REPL run:

"""

# ╔═╡ cea18fea-1105-4488-8f38-9c87fcc4f865
md"""

```julia
julia> Genie.newresource("movie")
```

"""

# ╔═╡ 535810b0-013e-45b9-ae02-c39fb48341ed
# hideall

Genie.newresource("movie")

# ╔═╡ 16bbed2f-200a-46cc-b1c0-e5b8d71e8419
md"""
## Creating the DB table using the database migration

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

"""

# ╔═╡ 1d6f258b-4cfa-4cdb-a2ef-3c3022b5aa9f
# hideall

begin
	migrations = true;
	migrations = readdir("$(dirname(pwd()))/Watchtonight/db/migrations");
end;

# ╔═╡ f75564ae-006c-45fe-b3af-f15302f378d4
# hideall

begin
	migrations;
	migration_file = migrations[2];
end;

# ╔═╡ 77682e4a-a00c-4d62-b83b-749e75abca49
# hideall

begin
	migrations;
	write("$(dirname(pwd()))/Watchtonight/db/migrations/$(migration_file)", """module CreateTableMovies

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
""");
end;

# ╔═╡ b2632755-b2ce-499f-828d-72f6697a99f9
md"""
#### Creating the migrations table

In order to be able to manage the app's migrations, we need to create the DB table used by SearchLight's migration system. This is easily done using SearchLight's generators:
"""

# ╔═╡ 4c624303-4972-4c0b-b73d-b762822b7f67
md"""

```julia
julia> using SearchLight
```
"""

# ╔═╡ 53f7baf7-2e26-4466-9d14-5680ca9c08ec
md"""

```julia
julia> SearchLight.Migration.create_migrations_table()
```
"""

# ╔═╡ b5dc2b0d-98a3-478c-b553-5c5f90ebd89d
# hideall 

begin
	migrations;
	SearchLight.Migration.create_migrations_table();
end;

# ╔═╡ 66f34751-b0f0-4f2f-a493-78b522dff835
md"""
### Running the migration

We can now check the status of the migrations:
"""

# ╔═╡ 43f7ac40-6e3f-497f-a730-2f56d9556c9a
md"""

```julia
julia> SearchLight.Migration.status()
```
"""

# ╔═╡ 34a73293-68d7-4d92-ab84-ee8cde46a1f6
# hideall

begin
	migrations;
	SearchLight.Migration.status();
end;

# ╔═╡ 74d3cd8a-9c28-4950-b50b-d86d6b246e92
md"""
And run the last migration UP:

"""

# ╔═╡ 046d2a13-c39d-41b6-bd81-a84438c069c0
md"""

```julia
julia> SearchLight.Migration.last_up()
```

"""

# ╔═╡ 36c6bbc3-1eb6-4da9-9a31-bbd94079f004
# hideall
begin
	migrations;
	SearchLight.Migration.last_up();
end;

# ╔═╡ 7b5c5389-4af8-4862-8645-89be6110df8d
md"""
## Creating the Movie model

Now that we have the database table, we need to create the model file which allows us manage the data. The file has already been created for us in `app/resources/movies/Movies.jl`. Edit it and make it look like this:
"""

# ╔═╡ 31a6e41a-30ba-11ec-00db-0727430de54c
md"""

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
"""

# ╔═╡ 1c07bcc0-fbf4-4a10-9641-95ff3c3ac0b4
# hideall

begin
	movie_model = true;
	movie_model_path = "$(dirname(pwd()))/Watchtonight/app/resources/movies/Movies.jl";
end;

# ╔═╡ 8d06c364-e663-4f64-8cc2-4117436d6f54
# hideall

begin
	movie_model;
	@assert isfile(movie_model_path) == true;
end;

# ╔═╡ 7f457902-a2d7-4839-a765-411612593b43
# hideall

begin
	movie_model;
	write(movie_model_path, """module Movies

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

	end""");
end;

# ╔═╡ 0dc2172d-3ed4-40aa-af96-f2b240d4a9b1
md"""
### Interacting with the movies data

Once our model is created, we can interact with the database:
"""

# ╔═╡ 73ff0fb9-f59c-4530-b07e-e5b5f4c17bed
md"""

```julia
julia> using Movies

julia> m = Movie(title = "Test movie", actors = "John Doe, Jane Doe")

```
"""

# ╔═╡ b9de07a9-2fda-48ad-bf6d-06d281930926
# hideall

movie_path = joinpath("$(dirname(pwd()))/Watchtonight/app/resources", "movies", "Movies.jl");

# ╔═╡ 5dabccfc-a606-4e24-8674-8abf29c95988
# hideall

begin
	movies=include(movie_path);
end;

# ╔═╡ ac20aa22-eb70-4e44-bd45-b70390bba572
# hideall

begin
	movie_model;
	m = movies.Movie(title = "Test movie", actors = "John Doe, Jane Doe");
end;

# ╔═╡ ef5219ee-20cb-4cb5-8198-66c1869c1edf
md"""
We can check if our movie object is persisted (saved to the db):
"""

# ╔═╡ eaf2641a-560b-482d-9c31-7d5f77a37c64
md"""

```julia
julia> ispersisted(m)
```
"""

# ╔═╡ 1e2ea760-809e-4b4d-8656-9a7f71cace00
# hideall

begin
	movie_model
	ispersisted(m)
end

# ╔═╡ 194e6c0f-437d-444f-9ac8-5f9831ecff2e
md"""
And we can save it:
"""

# ╔═╡ 6b9e8209-fd5e-4c7a-9edc-2c8c5550b9dd
md"""

```julia
julia> save(m)
```

"""

# ╔═╡ 31b15cd0-660a-4fe3-af1c-c07ebd9dde77
# hideall

begin
	movie_model
	save(m)
end

# ╔═╡ 7331830d-a61b-4f61-baf1-ae16dbbc9c63
md"""
Now we can run various methods against our data:
"""

# ╔═╡ 64346c63-1dc7-4c61-8784-210a6cf3973d
md"""

```julia
julia> count(Movie)
```
"""

# ╔═╡ dbfe50f6-1d94-4279-be76-655069148ca9
# hideall

begin
	movie_model
	count(movies.Movie)
end

# ╔═╡ e5f28cdb-ca29-42ce-afa1-914603179b63
md"""

```julia
julia> all(Movie)
```
"""

# ╔═╡ 349f7b7d-0586-4092-8017-127f771c5a30
# hideall

begin
	movie_model
	all(movies.Movie)
end

# ╔═╡ 0bc112e8-dd6b-46f9-9313-69aec4e62ec7
md"""
### Seeding the data

We're now ready to load the movie data into our database - we'll use a short seeding script. First make sure to place the CSV file into the `/db/seeds/` folder. Create the seeds file:
"""

# ╔═╡ 998b4a76-b8d0-48ea-a818-025f72b4f055
md"""

```julia
julia> touch(joinpath("db", "seeds", "seed_movies.jl"))
```
"""

# ╔═╡ fedb5f4b-235e-4a73-9fbd-34679fa58c15
# hideall

begin
	movie_model
	touch(joinpath("db", "seeds", "seed_movies.jl"))
end

# ╔═╡ 0b1e2272-7932-436b-8dae-43f9568ae115
md"""
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
    m.year = parse(Int, row.release_year)
    m.rating = row.rating
    m.categories = row.listed_in
    m.description = row.description

    save(m)
  end
end
```
"""

# ╔═╡ dbfa7df7-b744-4295-be30-62f5e04451d7
md"""
Add CSV.jl as a dependency of the project:
"""

# ╔═╡ 105574ab-db2b-43d9-8bbb-d7e932945d72
md"""

```julia
pkg> add CSV   # you can go to pkg mode by pressing <]> key and exit with <backspace> key
```
"""

# ╔═╡ db6de3fb-6958-4f24-a240-000a26d73775
md"""
And download the dataset:
"""

# ╔═╡ dd6f1b19-3673-45e6-a0f8-eefe77003ade
md"""

```julia
julia> download("https://raw.githubusercontent.com/essenciary/genie-watch-tonight/main/db/seeds/netflix_titles.csv", joinpath("db", "seeds", "netflix_titles.csv"))
```
"""

# ╔═╡ 97842024-670f-4f99-95f7-6a5694953f20
# hideall

begin
	csv_seed = true
	download("https://raw.githubusercontent.com/essenciary/genie-watch-tonight/main/db/seeds/netflix_titles.csv", joinpath("db", "seeds", "netflix_titles.csv"))
end

# ╔═╡ 44793e6e-b806-4493-8049-d96fe3cf9f3f
# hideall

begin
	csv_seed;
	seed_path = joinpath("$(dirname(pwd()))/Watchtonight/db", "seeds", "seed_movies.jl");
end;

# ╔═╡ f4e2899d-3158-4a92-8a83-86223cb570ef
# hideall

begin
	csv_seed;
	@assert isfile(seed_path) == true;
end;

# ╔═╡ cb851bb7-85ce-4fb9-9d65-1f65bf2abd45
# hideall 
begin
	csv_seed;
	write(seed_path, """using SearchLight, Movies
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
    m.year = parse(Int, row.release_year)
    m.rating = row.rating
    m.categories = row.listed_in
    m.description = row.description

    save(m)
  end
	end""");
end;

# ╔═╡ 140cc54d-edd0-4883-9075-e5aa9583658f
# hideall

begin
	Base.convert(::Type{String}, _::Missing) = ""
	Base.convert(::Type{Int}, _::Missing) = 0
	Base.convert(::Type{Int}, s::String) = parse(Int, s)

	function seed()
	  csv_path = joinpath("$(dirname(pwd()))/Watchtonight/db", "seeds", "netflix_titles.csv")
	  for row in CSV.Rows(csv_path, limit = 1_000)
		m = movies.Movie()

		m.type = row.type
		m.title = row.title
		m.directors = row.director
		m.actors = row.cast
		m.country = row.country
		m.year = parse(Int, row.release_year)
		m.rating = row.rating
		m.categories = row.listed_in
		m.description = row.description

		save(m)
	  end
	end
		end;

# ╔═╡ dcc10511-87ae-49fc-a392-7305b98ffe58
md"""
Now, to seed the db: from Netflix CSV file to SQLite we will use `seed()` method
"""

# ╔═╡ a7413152-37ca-475e-be44-897c7b0591ea
md"""

```julia
julia> include(joinpath("db", "seeds", "seed_movies.jl"))
julia> seed()
```
"""

# ╔═╡ 1ae5e7ff-f917-4cc5-b431-1e04437f6f82
# hideall

begin
	csv_seed;
	seed();
end;

# ╔═╡ 9a9f9e32-52b0-4b60-ab3f-e6d505e2e292
md"""
## Setting up the web page

We'll start by adding the route to our handler function. Let's open the `routes.jl` file and add:

```julia
using Genie.Router
using MoviesController

route("/") do
  serve_static_file("welcome.html")
end

route("/movies", MoviesController.index)
```
"""

# ╔═╡ 31da2638-3d55-4860-b6c0-0ca859274471
# hideall

begin
	routing = true;
	routesPath = "$(dirname(pwd()))/Watchtonight/routes.jl";
end;

# ╔═╡ 5678a0e0-6931-4a4e-9b77-8eb6bdb92946
# hideall

begin
	routing;
	write(routesPath, """# routes.jl
using MoviesController

route("/movies", MoviesController.index)
""");
end;

# ╔═╡ 5a97224a-3abd-44e9-a7be-9594ad802f6b
md"""
This route declares that the `/movies` URL will be handled by the `MoviesController.index` index function. Let's put it in by editing `/app/resources/movies/MoviesController.jl`:

```julia
module MoviesController

function index()
  "Welcome to movies list!"
end

end
```
"""

# ╔═╡ 244b4cef-f3c2-4d2c-ba31-40d5f438d94c
# hideall

begin
	controlling = true;
	controllerPath = joinpath("$(dirname(pwd()))/Watchtonight/app/resources", "movies", "MoviesController.jl");
end;

# ╔═╡ 4aac6bd3-d4c4-495b-ae98-339fdfab2dcd
# hideall

begin
	controlling;
	write(controllerPath, """module MoviesController

function index()
  "Welcome to movies list!"
end

	end""");
end;

# ╔═╡ 7d6485e6-61a3-4c8c-803c-b5f5c9471af5
md"""
You can start Genie Server by running:
```julia-repl
julia> up()
```

If we navigate to <http://127.0.0.1:8000/movies> we should see the welcome. You can stop the server with
`down()` function. To execute further command in same repl session, hit <enter> key and you'll see `julia>` prompt.

Let's make this more useful though and display a random movie upon landing here:

```julia
module MoviesController

using Genie.Renderer.Html, SearchLight, Movies

function index()
  html(:movies, :index, movies = rand(Movie))
end

end
```

"""

# ╔═╡ 20ace881-23a6-40dc-bab9-4ee3673deb03
# hideall

begin
	controlling;
	write(controllerPath, """module MoviesController

using Genie.Renderer.Html, SearchLight, Movies

function index()
  html(:movies, :index, movies = rand(Movie))
end

	end""");
end;

# ╔═╡ deb228d5-be6a-42a2-a1bc-38e9e08d52f8
md"""
The index function renders the `/app/resources/movies/views/index.jl.html` view file as HTML, passing it a random movie into the `movies` instance. Since we don't have the view file yet, let's add it:
"""

# ╔═╡ 3d6e7123-6c08-4196-9301-21cd4f6a46a2
md"""

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "index.jl.html"))
```
"""

# ╔═╡ 7169ea83-cbb1-441a-ac82-1a665d92c7eb
# hideall

begin
	viewing = true;
	viewPath1 = joinpath("$(dirname(pwd()))/Watchtonight/app/resources/movies", "views", "index.jl.html");
end;

# ╔═╡ a1d11637-1fc4-407b-ab3f-1c38868316d0
# hideall

begin
	viewing;
	touch(viewPath1);
end;

# ╔═╡ d01e740a-bcba-4960-8b68-ea2a3220b044
md"""
Make it look like this:
"""

# ╔═╡ f8add9e4-c46c-44a8-a1ff-672ed01af385
md"""

```
<h1 class="display-1 text-center">Watch tonight</h1>
<%
if ! isempty(movies)
  for_each(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>
```

"""

# ╔═╡ bf506234-4707-4cd3-9938-89a1b1d35493
# hideall

begin
	viewing;
	write(viewPath1, """<h1 class="display-1 text-center">Watch tonight</h1>
<%
if ! isempty(movies)
  for_each(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>""");
end;

# ╔═╡ 54c23483-946a-484c-bd23-78b356c83b71
md"""
Now to create the `_movie.jl.html` partial file to render a movie object:
"""

# ╔═╡ ddd70fb2-a13b-464f-848b-273172182558
md"""

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "_movie.jl.html"))
```
"""

# ╔═╡ dde8e6bc-e090-47a4-8277-75e0353e911b
# hideall

begin
	viewing;
	viewPath2 = joinpath("$(dirname(pwd()))/Watchtonight/app/resources/movies", "views", "_movie.jl.html");
end;

# ╔═╡ af9524f8-8609-43a2-a0e4-8af8fd3e5d19
# hideall 

begin
	viewing;
	touch(viewPath2);
end;

# ╔═╡ 8792aa03-e1fb-4f25-bd29-02afdce7571b
md"""
Edit it like this:
"""

# ╔═╡ ecd4b8fe-15b0-4fa8-b628-9df3eaa4cb65
md"""
```
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
"""

# ╔═╡ d18f1222-365e-4ff8-b653-17c20ce6bb2b
# hideall

begin
	viewing;
	write(viewPath2, """<div class="container" style="margin-top: 40px;">
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
</div>""");
end;

# ╔═╡ 5d411fc8-f5c3-472d-b252-17495b824768
md"""
And finally, the `_no_results.jl.html` partial:
"""

# ╔═╡ 9bcc6884-3b39-416d-a576-0c49613a81fa
md"""

```julia
julia> touch(joinpath("app", "resources", "movies", "views", "_no_results.jl.html"))
```
"""

# ╔═╡ 3bd27349-f8b6-484b-ae69-fe5628ee2063
# hideall

begin
	viewing;
	viewPath3 = joinpath("$(dirname(pwd()))/Watchtonight/app/resources/movies", "views", "_no_results.jl.html");
end;

# ╔═╡ 7c21df26-827d-4b8a-a490-749d418e0b72
# hideall

begin
	viewing;
	touch(viewPath3);
end;

# ╔═╡ f3126646-c059-4988-a453-148411313171
md"""
```
<h4 class="container">
  Sorry, no results were found for "$(params(:search_movies))"
</h4>
```
"""

# ╔═╡ 7c0c8cda-39e6-4d07-ae39-661ac3f211fe
# hideall

begin
	viewing;
	write(viewPath3, """<h4 class="container">
  Sorry, no results were found for "\$(params(:search_movies))"
</h4>""");
	end;

# ╔═╡ 0a4a3007-5335-44c9-b06c-d26cdd0c2a6b
md"""
### Using the layout file

Let's make the web page nicer by loading the Twitter Bootstrap CSS library. As it will be used across all the pages of the website, we'll load it in the main layout file. Edit `/app/layouts/app.jl.html` to look like this:

```
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

You can check your progress at <http://127.0.0.1:8000/movies>
"""

# ╔═╡ 28c4ecbb-c726-4a2e-b62d-66b2d757e100
# hideall

begin
	viewing;
	viewPath4 = joinpath("$(dirname(pwd()))/Watchtonight/app", "layouts", "app.jl.html");
end;

# ╔═╡ 9d35b556-1660-45a5-863e-87c11f605771
# hideall

begin
	viewing;
	chmod(viewPath4, 0o777);
	touch(viewPath4);
end;

# ╔═╡ 1d530817-d2e1-4633-b52a-dd0f88f4c092
# hideall

begin
	viewing;
	write(viewPath4, """<!DOCTYPE html>
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
</html>""");
end;

# ╔═╡ e6d8b7a5-39d0-40a8-93fc-571e8300edbf
md"""

## Adding the search feature

Now that we can display titles, it's time to implement the search feature. We'll add a search form onto our page. Edit `/app/resources/movies/views/index.jl.html` to look like this:

```
<h1 class="display-1 text-center">Watch tonight</h1>

<div class="container" style="margin-top: 40px;">
  <form action="$( linkto(:search_movies) )">
    <input class="form-control form-control-lg" type="search" name="search_movies" placeholder="Search for movies and TV shows" />
  </form>
</div>

<%
if ! isempty(movies)
  for_each(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>
```
"""

# ╔═╡ 3a743674-b1d1-40d0-a6da-fbc36fd46c12
# hideall

begin
	viewing;
	write(viewPath1, """<h1 class="display-1 text-center">Watch tonight</h1>

<div class="container" style="margin-top: 40px;">
  <form action="$( linkto(:search_movies) )">
    <input class="form-control form-control-lg" type="search" name="search_movies" placeholder="Search for movies and TV shows" />
  </form>
</div>

<%
if ! isempty(movies)
  for_each(movies) do movie
    partial(joinpath(Genie.config.path_resources, "movies", "views", "_movie.jl.html"), movie = movie)
  end
else
  partial(joinpath(Genie.config.path_resources, "movies", "views", "_no_results.jl.html"))
end
%>""");
end;

# ╔═╡ 6ce6df26-e700-44b2-823a-4ab334b5ef3f
md"""

We have added a HTML `<form>` which submits a query term over GET.

Next, add the route in `routes.jl`:

```julia
# ... routes.jl
route("/movies/search", MoviesController.search, named = :search_movies)
```
"""

# ╔═╡ eb6593a4-7d3b-47b8-9683-f8621666aaa9
# hideall

begin
	routing;
	write(routesPath, """# routes.jl
using MoviesController

route("/movies", MoviesController.index)
route("/movies/search", MoviesController.search, named = :search_movies)
""");
end;

# ╔═╡ 94cde687-0027-4e62-be10-2020bf852170
md"""
And the `MoviesController.search` function after updating the `using` section in `MoviesController.jl`:

```julia
using Genie, Genie.Renderer, Genie.Renderer.Html, SearchLight, Movies


function search()
  isempty(strip(params(:search_movies))) && redirect(:get_movies)

  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * params(:search_movies) * '%'], 4)))

  html(:movies, :index, movies = movies)
end
```

"""

# ╔═╡ ad75fd6a-b0d9-4d83-a000-2edd12f20902
# hideall

begin
	controlling;
	write(controllerPath, """module MoviesController

using Genie, Genie.Renderer, Genie.Renderer.Html, SearchLight, Movies

function index()
  html(:movies, :index, movies = rand(Movie))
end

function search()
  isempty(strip(params(:search_movies))) && redirect(:get_movies)

  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * params(:search_movies) * '%'], 4)))

  html(:movies, :index, movies = movies)
end

	end""");
end;

# ╔═╡ 516b71bd-7557-40eb-97ce-2ae57a5fcff0
md"""

Time to check our progress: <http://127.0.0.1:8000/movies>

"""

# ╔═╡ 7222ad76-b824-442e-9a24-a373bff9ce63
md"""
## Building the REST API

Let's start by adding a new route for the API search:

```julia
route("/movies/search_api", MoviesController.search_api)
```
"""

# ╔═╡ fcf1fe71-ad93-4af0-a04f-ffeea121edcd
# hideall

begin
	routing;
	write(routesPath, """# routes.jl
using MoviesController

route("/movies", MoviesController.index)
route("/movies/search", MoviesController.search, named = :search_movies)
route("/movies/search_api", MoviesController.search_api)
""");
end;

# ╔═╡ 99365894-b104-4fd9-982c-7a8c53e838c5
md"""
With the corresponding `search_api` method in the `MoviesController` model:

```julia
using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, SearchLight, Movies

# previous code

function search_api()
  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * params(:search_movies) * '%'], 4)))

  json(Dict("movies" => movies))
end
```
"""

# ╔═╡ 2ea91d6b-7034-48e1-813d-b1409efff537
# hideall 

begin
	controlling;
	write(controllerPath, """module MoviesController

using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, SearchLight, Movies

function index()
  html(:movies, :index, movies = rand(Movie))
end

function search_api()
  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * params(:search_movies) * '%'], 4)))

  json(Dict("movies" => movies))
end
		
function search()
  isempty(strip(params(:search_movies))) && redirect(:get_movies)

  movies = find(Movie,
              SQLWhereExpression("title LIKE ? OR categories LIKE ? OR description LIKE ? OR actors LIKE ?",
                                  repeat(['%' * params(:search_movies) * '%'], 4)))

  html(:movies, :index, movies = movies)
end



	end""");
end;

# ╔═╡ 9e4f871e-50dd-47a5-a8a9-9de4af50b094
md"""

```julia
julia> include("routes.jl")
```
"""

# ╔═╡ ed5e46d7-6e28-461d-be2f-2ad89e5ccba5
md"""

Time to check our progress: <http://127.0.0.1:8000/movies/search_api?search_movies=7>

You can also use Postman to request the API and get JSON back
"""

# ╔═╡ 78ed9e47-6e76-451a-a844-d8c030d33224
md"""

## Bonus

Genie makes it easy to add database backed authentication for restricted area of a website, by using the `GenieAuthentication` plugin. Start by adding package:

```julia
julia> using Pkg
julia> Pkg.add("GenieAuthentication")

julia> using GenieAuthentication
```

Now, to install the plugin files:

```julia
julia> GenieAuthentication.install(@__DIR__)
```

The plugin has created a create table migration that we need to run `UP`:

```julia
julia> using SearchLight
julia> SearchLight.Migration.up("CreateTableUsers")
```

Let's generate an Admin controller that we'll want to protect by login:

```julia
julia> Genie.Generator.newcontroller("Admin", pluralize = false)
```

Only this time, let's load the plugin into the app manually. Upon restarting the application, the plugin will be automatically
loaded by `Genie`:

```julia
julia> include(joinpath("plugins", "genie_authentication.jl"))
```

Time to create an admin user for logging in:

```julia
julia> using Users

julia> u = User(email = "admin@admin", name = "Admin", password = Users.hash_password("admin"), username = "admin")

julia> save!(u)
```

We'll also need a route for the admin area in `routes.jl`:

```julia
using AdminController

route("/admin/movies", AdminController.index, named = :get_home)
```

And finally, the controller code in `AdminController.jl`:

```julia
module AdminController

using GenieAuthentication, Genie.Renderer, Genie.Exceptions, Genie.Renderer.Html

function index()
  @authenticated!
  h1("Welcome Admin") |> html
end

end
```

If we navigate to <http://127.0.0.1:8000/admin/movies> we'll be asked to logged in. Using `admin` for the user and `admin` for the password will allow us to access the password protected section.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
SearchLight = "340e8cb6-72eb-11e8-37ce-c97ebeb32050"

[compat]
CSV = "~0.10.2"
Genie = "~4.9.1"
SearchLight = "~2.1.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ArgParse]]
deps = ["Logging", "TextWrap"]
git-tree-sha1 = "3102bce13da501c9104df33549f511cd25264d7d"
uuid = "c7e460c6-2fb9-53a9-8c5b-16f535851c63"
version = "1.1.4"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[CSTParser]]
deps = ["Tokenize"]
git-tree-sha1 = "f9a6389348207faf5e5c62cbc7e89d19688d338a"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.3.0"

[[CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "9519274b50500b8029973d241d32cfbf0b127d97"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.2"

[[CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[CommonMark]]
deps = ["Crayons", "JSON", "URIs"]
git-tree-sha1 = "4aff51293dbdbd268df314827b7f409ea57f5b70"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.5"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "ae02104e835f219b8930c7664b8012c93475c340"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.2"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "04d13bfa8ef11720c24e4d840c0033d145537df7"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.17"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"

[[Genie]]
deps = ["ArgParse", "Dates", "Distributed", "EzXML", "FilePathsBase", "HTTP", "HttpCommon", "Inflector", "JSON3", "JuliaFormatter", "Logging", "Markdown", "MbedTLS", "Millboard", "Nettle", "OrderedCollections", "Pkg", "REPL", "Random", "Reexport", "Revise", "SHA", "Serialization", "Sockets", "UUIDs", "Unicode", "VersionCheck", "YAML"]
git-tree-sha1 = "d0362686961375e910e437c76ff4ed6f31b54fef"
uuid = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
version = "4.9.1"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[HttpCommon]]
deps = ["Dates", "Nullables", "Test", "URIParser"]
git-tree-sha1 = "46313284237aa6ca67a6bce6d6fbd323d19cff59"
uuid = "77172c1b-203f-54ac-aa54-3f1198fe9f90"
version = "0.5.0"

[[Inflector]]
deps = ["Unicode"]
git-tree-sha1 = "8555b54ddf27806b070ce1d1cf623e1feb13750c"
uuid = "6d011eab-0732-4556-8808-e463c76bf3b6"
version = "1.0.1"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JSON3]]
deps = ["Dates", "Mmap", "Parsers", "StructTypes", "UUIDs"]
git-tree-sha1 = "7d58534ffb62cd947950b3aa9b993e63307a6125"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.9.2"

[[JuliaFormatter]]
deps = ["CSTParser", "CommonMark", "DataStructures", "Pkg", "Tokenize"]
git-tree-sha1 = "da0c8830cebe2337093bb46fc117498517a9df80"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "0.21.2"

[[JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "6ca01d8e5bc75d178e8ac2d1f741d02946dc1853"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.2"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "f46e8f4e38882b32dcc11c8d31c131d556063f39"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.0"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Millboard]]
git-tree-sha1 = "ea6a5b7e56e76d8051023faaa11d91d1d881dac3"
uuid = "39ec1447-df44-5f4c-beaa-866f30b4d3b2"
version = "0.2.5"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[Nettle]]
deps = ["Libdl", "Nettle_jll"]
git-tree-sha1 = "a68340b9edfd98d0ed96aee8137cb716ea3b6dea"
uuid = "49dea1ee-f6fa-5aa6-9a11-8816cee7d4b9"
version = "0.5.1"

[[Nettle_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "eca63e3847dad608cfa6a3329b95ef674c7160b4"
uuid = "4c82536e-c426-54e4-b420-14f461c4ed8b"
version = "3.7.2+0"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Nullables]]
git-tree-sha1 = "8f87854cc8f3685a60689d8edecaa29d2251979b"
uuid = "4d1e1d77-625e-5b40-9113-a560ec7a8ecd"
version = "1.0.0"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0b5cfbb704034b5b4c1869e36634438a047df065"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.1"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "2f9d4d6679b5f0394c52731db3794166f49d5131"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.3.1"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SearchLight]]
deps = ["DataFrames", "Dates", "Distributed", "Inflector", "JSON3", "Logging", "Millboard", "OrderedCollections", "Reexport", "SHA", "Unicode", "YAML"]
git-tree-sha1 = "5c6d16346ef5af1b74154f44c61f8ae28a1ec15f"
uuid = "340e8cb6-72eb-11e8-37ce-c97ebeb32050"
version = "2.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "15dfe6b103c2a993be24404124b8791a09460983"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.11"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StringEncodings]]
deps = ["Libiconv_jll"]
git-tree-sha1 = "50ccd5ddb00d19392577902f0079267a72c5ab04"
uuid = "69024149-9ee7-55f6-a4c4-859efe599b68"
version = "0.3.5"

[[StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "d24a825a95a6d98c385001212dc9020d609f2d4f"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.8.1"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TextWrap]]
git-tree-sha1 = "9250ef9b01b66667380cf3275b3f7488d0e25faf"
uuid = "b718987f-49a8-5099-9789-dcd902bef87d"
version = "1.0.1"

[[Tokenize]]
git-tree-sha1 = "0952c9cee34988092d73a5708780b3917166a0dd"
uuid = "0796e94c-ce3b-5d07-9a54-7f471281c624"
version = "0.5.21"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[UrlDownload]]
deps = ["HTTP", "ProgressMeter"]
git-tree-sha1 = "05f86730c7a53c9da603bd506a4fc9ad0851171c"
uuid = "856ac37a-3032-4c1c-9122-f86d88358c8b"
version = "1.0.0"

[[VersionCheck]]
deps = ["Dates", "JSON3", "Logging", "Pkg", "Random", "Scratch", "UrlDownload"]
git-tree-sha1 = "89ef2431dd59344ebaf052d0737205854ded0c62"
uuid = "a637dc6b-bca1-447e-a4fa-35264c9d0580"
version = "0.2.0"

[[WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "c69f9da3ff2f4f02e811c3323c22e5dfcb584cfa"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.1"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[YAML]]
deps = ["Base64", "Dates", "Printf", "StringEncodings"]
git-tree-sha1 = "3c6e8b9f5cdaaa21340f841653942e1a6b6561e5"
uuid = "ddb6d928-2868-570f-bddf-ab3f9cf99eb6"
version = "0.4.7"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─476096fa-2ff7-11ec-3426-f77a9804eb1a
# ╠═63864c9f-42e6-4cdf-8b67-be0f4f00a51e
# ╟─189c8d2a-30b1-11ec-0e97-b7704e8c2588
# ╠═f220c2b5-99c4-481e-9d09-334934d964b2
# ╟─374b0835-316e-4737-8610-92a6febfd986
# ╟─a608794b-cfaf-4e41-83e7-7f9f700b3d1a
# ╠═2e4cd23d-472b-4161-a592-9f92b0f4b3b1
# ╠═bc4234b8-67d4-4844-a907-d45a4649db8b
# ╠═eebc2a27-ac29-4f70-998c-d2a5be7a29ce
# ╠═65ea2335-4d7f-4e48-9aef-453141d3551c
# ╟─89f2cc70-c656-4aa9-8ea6-ca739871e0d6
# ╟─7a63f66a-de61-4a1f-a73a-577cbbaf9622
# ╠═8cf3615d-a101-4c50-926d-172703c2ee70
# ╠═bb0796e4-e5ad-4d5d-b59c-9af9bfec6eb7
# ╟─17df041b-e6c2-4719-a81d-a8f6e2f1bc01
# ╟─871252c0-ad15-44d6-ac5e-572eebc2577e
# ╠═9ac74156-4af7-48d8-989b-38f65ea3c411
# ╠═772f1056-eb1a-4a78-bd16-52578a0fc5de
# ╠═0612248e-2ca1-4643-879a-21b13bd4906f
# ╟─cea18fea-1105-4488-8f38-9c87fcc4f865
# ╠═535810b0-013e-45b9-ae02-c39fb48341ed
# ╟─16bbed2f-200a-46cc-b1c0-e5b8d71e8419
# ╠═1d6f258b-4cfa-4cdb-a2ef-3c3022b5aa9f
# ╠═f75564ae-006c-45fe-b3af-f15302f378d4
# ╠═77682e4a-a00c-4d62-b83b-749e75abca49
# ╟─b2632755-b2ce-499f-828d-72f6697a99f9
# ╟─4c624303-4972-4c0b-b73d-b762822b7f67
# ╠═9ab99155-0cdf-4b13-9719-61a6608bedc7
# ╟─53f7baf7-2e26-4466-9d14-5680ca9c08ec
# ╠═b5dc2b0d-98a3-478c-b553-5c5f90ebd89d
# ╟─66f34751-b0f0-4f2f-a493-78b522dff835
# ╟─43f7ac40-6e3f-497f-a730-2f56d9556c9a
# ╠═34a73293-68d7-4d92-ab84-ee8cde46a1f6
# ╟─74d3cd8a-9c28-4950-b50b-d86d6b246e92
# ╟─046d2a13-c39d-41b6-bd81-a84438c069c0
# ╠═36c6bbc3-1eb6-4da9-9a31-bbd94079f004
# ╟─7b5c5389-4af8-4862-8645-89be6110df8d
# ╟─31a6e41a-30ba-11ec-00db-0727430de54c
# ╠═1c07bcc0-fbf4-4a10-9641-95ff3c3ac0b4
# ╠═8d06c364-e663-4f64-8cc2-4117436d6f54
# ╠═7f457902-a2d7-4839-a765-411612593b43
# ╟─0dc2172d-3ed4-40aa-af96-f2b240d4a9b1
# ╟─73ff0fb9-f59c-4530-b07e-e5b5f4c17bed
# ╠═b9de07a9-2fda-48ad-bf6d-06d281930926
# ╠═5dabccfc-a606-4e24-8674-8abf29c95988
# ╠═ac20aa22-eb70-4e44-bd45-b70390bba572
# ╟─ef5219ee-20cb-4cb5-8198-66c1869c1edf
# ╟─eaf2641a-560b-482d-9c31-7d5f77a37c64
# ╠═1e2ea760-809e-4b4d-8656-9a7f71cace00
# ╟─194e6c0f-437d-444f-9ac8-5f9831ecff2e
# ╟─6b9e8209-fd5e-4c7a-9edc-2c8c5550b9dd
# ╠═31b15cd0-660a-4fe3-af1c-c07ebd9dde77
# ╟─7331830d-a61b-4f61-baf1-ae16dbbc9c63
# ╟─64346c63-1dc7-4c61-8784-210a6cf3973d
# ╠═dbfe50f6-1d94-4279-be76-655069148ca9
# ╟─e5f28cdb-ca29-42ce-afa1-914603179b63
# ╠═349f7b7d-0586-4092-8017-127f771c5a30
# ╟─0bc112e8-dd6b-46f9-9313-69aec4e62ec7
# ╟─998b4a76-b8d0-48ea-a818-025f72b4f055
# ╠═fedb5f4b-235e-4a73-9fbd-34679fa58c15
# ╟─0b1e2272-7932-436b-8dae-43f9568ae115
# ╟─dbfa7df7-b744-4295-be30-62f5e04451d7
# ╟─105574ab-db2b-43d9-8bbb-d7e932945d72
# ╠═bd0482b9-ebec-425d-99c0-e31e5af2e498
# ╟─db6de3fb-6958-4f24-a240-000a26d73775
# ╟─dd6f1b19-3673-45e6-a0f8-eefe77003ade
# ╠═97842024-670f-4f99-95f7-6a5694953f20
# ╠═44793e6e-b806-4493-8049-d96fe3cf9f3f
# ╠═f4e2899d-3158-4a92-8a83-86223cb570ef
# ╠═cb851bb7-85ce-4fb9-9d65-1f65bf2abd45
# ╠═140cc54d-edd0-4883-9075-e5aa9583658f
# ╟─dcc10511-87ae-49fc-a392-7305b98ffe58
# ╟─a7413152-37ca-475e-be44-897c7b0591ea
# ╠═1ae5e7ff-f917-4cc5-b431-1e04437f6f82
# ╟─9a9f9e32-52b0-4b60-ab3f-e6d505e2e292
# ╠═31da2638-3d55-4860-b6c0-0ca859274471
# ╠═5678a0e0-6931-4a4e-9b77-8eb6bdb92946
# ╟─5a97224a-3abd-44e9-a7be-9594ad802f6b
# ╠═244b4cef-f3c2-4d2c-ba31-40d5f438d94c
# ╠═4aac6bd3-d4c4-495b-ae98-339fdfab2dcd
# ╟─7d6485e6-61a3-4c8c-803c-b5f5c9471af5
# ╠═20ace881-23a6-40dc-bab9-4ee3673deb03
# ╟─deb228d5-be6a-42a2-a1bc-38e9e08d52f8
# ╟─3d6e7123-6c08-4196-9301-21cd4f6a46a2
# ╠═7169ea83-cbb1-441a-ac82-1a665d92c7eb
# ╠═a1d11637-1fc4-407b-ab3f-1c38868316d0
# ╟─d01e740a-bcba-4960-8b68-ea2a3220b044
# ╟─f8add9e4-c46c-44a8-a1ff-672ed01af385
# ╠═bf506234-4707-4cd3-9938-89a1b1d35493
# ╟─54c23483-946a-484c-bd23-78b356c83b71
# ╟─ddd70fb2-a13b-464f-848b-273172182558
# ╠═dde8e6bc-e090-47a4-8277-75e0353e911b
# ╠═af9524f8-8609-43a2-a0e4-8af8fd3e5d19
# ╟─8792aa03-e1fb-4f25-bd29-02afdce7571b
# ╟─ecd4b8fe-15b0-4fa8-b628-9df3eaa4cb65
# ╠═d18f1222-365e-4ff8-b653-17c20ce6bb2b
# ╟─5d411fc8-f5c3-472d-b252-17495b824768
# ╟─9bcc6884-3b39-416d-a576-0c49613a81fa
# ╠═3bd27349-f8b6-484b-ae69-fe5628ee2063
# ╠═7c21df26-827d-4b8a-a490-749d418e0b72
# ╟─f3126646-c059-4988-a453-148411313171
# ╠═7c0c8cda-39e6-4d07-ae39-661ac3f211fe
# ╟─0a4a3007-5335-44c9-b06c-d26cdd0c2a6b
# ╠═28c4ecbb-c726-4a2e-b62d-66b2d757e100
# ╠═9d35b556-1660-45a5-863e-87c11f605771
# ╠═1d530817-d2e1-4633-b52a-dd0f88f4c092
# ╟─e6d8b7a5-39d0-40a8-93fc-571e8300edbf
# ╠═3a743674-b1d1-40d0-a6da-fbc36fd46c12
# ╟─6ce6df26-e700-44b2-823a-4ab334b5ef3f
# ╠═eb6593a4-7d3b-47b8-9683-f8621666aaa9
# ╟─94cde687-0027-4e62-be10-2020bf852170
# ╠═ad75fd6a-b0d9-4d83-a000-2edd12f20902
# ╟─516b71bd-7557-40eb-97ce-2ae57a5fcff0
# ╟─7222ad76-b824-442e-9a24-a373bff9ce63
# ╠═fcf1fe71-ad93-4af0-a04f-ffeea121edcd
# ╟─99365894-b104-4fd9-982c-7a8c53e838c5
# ╠═2ea91d6b-7034-48e1-813d-b1409efff537
# ╟─9e4f871e-50dd-47a5-a8a9-9de4af50b094
# ╟─ed5e46d7-6e28-461d-be2f-2ad89e5ccba5
# ╟─78ed9e47-6e76-451a-a844-d8c030d33224
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
