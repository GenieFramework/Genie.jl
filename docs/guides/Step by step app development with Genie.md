# Step By Step: Web App Development with Genie and Julia

## Intro
Genie is a web framework for developing professional grade web applications. Genie builds on top of Julia's excellent performance and readable syntax, contributing a rich API for productive web development. Genie follows the MVC design pattern, in the style of other established web frameworks from different languages, like Ruby's Rails, Python's Django or Elixir's Phoenix.

In this guide you'll learn how to build a reasonably complex web application using Genie and Julia. Our app, called Chirper, will allow the users to post small messages which will be shared on the app's wall.

We'll start with the basic features like scaffolding our app, setting up our database connection, creating views, handling POST data, validating and persisting data through models and unit testing (Part 1). Then we'll progressively advance towards more complex features like model relationships, and we'll learn about useful functionalities like caching, authentication and authorisation while adding an admin area (Part 2). Once we're happy with the feature set, we'll see how build a REST API to expose our data (Part 3). Then we'll focus on enhancing the front-end, building rich, responsive UIs using web sockets and Genie's seamless integration with Webpack and Yarn (Part 4). Finally, once our app is complete, we'll learn to add integration tests, configure it for production use and deploy it on a server in the cloud (Part 5).

You are encouraged to actively follow through the code, by developing the app in parallel. The only technical requirement for following along is the latest stable Julia version. Familiarity with web development and Julia is assumed. Things will be explained step-by-step but we won't cover web development basics -- nor coding with Julia. That being said, enjoy!

---

# Part 1

## Scaffolding our app
The first thing that we need to do is to setup the file structure of our app. Genie uses "convention over configuration" -- that is, it employs sensible defaults, expecting certain files and folders in certain locations. In exchange, Genie will be able to automatically load and expose dependencies, while ensuring that the application stays maintainable and predictable as the codebase grows. Genie does not require setting up these files manually - instead, it provides a rich set of generators for scaffolding every component of the web app.

The only requirement to get things started is installing Genie itself:
```julia
julia> using Pkg
julia> Pkg.clone("htts://github.com/essenciary/Genie.jl") # Soon to be Pkg.add("Genie")
julia> using Genie
```

Now we can ask Genie to scaffold our app -- which we'll name "chirper".
```julia
julia> Genie.REPL.new_app("chirper")
```
This creates a new folder in the current directory, `./chirper`, and sets up the application's files.

You'll see the output in the console, informing you about the status of the operation:
```julia
info: Done! New app created at /Users/adrian/Dropbox/Projects/chirper
info: Looking for dependencies
info: Checking for Flax rendering engine support
info: Finished adding dependencies
info: Starting your brand new Genie app - hang tight!
```

Once the app is ready, it will be automatically started. This means that:
- Julia will `cd()` into the app's folder
- will load the Genie app environment
- will take you to a Genie REPL -- which is a Julia REPL, so you have all the power of Julia at your disposal -- where you'll have access to Genie's API
- the Genie REPL is indicated by the custom prompt `genie>`

To manually start the application in the future you will have to follow more or less the same steps:
* from the terminal `cd` into the app's folder: `$ cd /path/to/chirper`
* load the REPL by running in the terminal: `$ bin/repl`
* the Genie environment will load - when done you'll find yourself at the `genie>` prompt.

Once Genie is loaded, we can check that everything worked well by starting up a server and taking it for a spin:
```julia
genie> server = AppServer.startup()
```
You can now visit [localhost:8000](http://localhost:8000) in your browser - you will be welcomed by our very helpful genie. That's pretty good - but it's time we build our own home page.

## Setting up the home page
Genie uses a route file to map web requests to Julia functions. These functions process the request and return a response. The routes are defined within the `config/routes.jl` file. Right now, the file looks like this (the default):
```julia
using Router

route("/") do
  Router.serve_static_file("/welcome.html")
end
```

For starters, it brings the `Router` module into scope. Then it defines a `route` for the root page, `/` -- which is handled by an anonymous function which calls `Router.serve_static_file`. The `serve_static_file` function returns the content of the `public/welcome.html` static file. This is the file we have seen when we accessed the website.

Let's replace the default Genie home page with a simple custom one. This time we'll do it the manual way so you can understand how things work - but in the future we'll use Genie's generators. We need to create a new folder under `app/resources` -- let's call it `home`, cause it's for our _home_ page. Inside `home/`, add a `views/` folder. You can use your file manager if you want -- I'll use Julia:
```julia
genie> mkpath("app/resources/home/views")
```

Inside views, let's add the file for our home page. Genie supports both HTML and Markdown views (pages). For now, let's setup a simple markdown page called `home_page.md`:
```julia
genie> touch("app/resources/home/views/home_page.md")
```

We can now edit it. This command will open the "home_page.md" file with your default editor:
```julia
genie> edit("app/resources/home/views/home_page.md")
```
Add the following content and save the file:
```markdown
# Welcome to Chirper!
Chirper is a cool website which allows you to post short public messages for the Chirper community -- and to follow other chirpers and see their messages!
```

Finally, we need to edit our routes file. We can no longer use the `serve_static_file` function because the markdown file needs to be parsed and converted into HTML. Instead, we'll call the `respond_with_html` function -- which takes at least two arguments: the name of the resource, of the folder (in our case `home`) and the name of the view file (in our case, `home_page`):
```julia
route("/") do
  respond_with_html("home", "home_page.md")
end
```

## Configuring the database
SearchLight is Genie's ORM layer. It works seamlessly with all the major relational databases supported by Julia: SQLite, MySQL and PostgreSQL -- with ODBC and JDBC support in the works. Thanks to its DSL for managing and querying databases, you can, for instance, prototype and develop using SQLite and deploy in production using MySQL. Let's add a SQLite backend for our app.

For start, make sure that you have the `SQLite.jl` package installed. You can check the package's README at the [SQLite repo page](https://github.com/JuliaDatabases/SQLite.jl).

Once you have it installed, edit the `config/database.yml` file:
```julia
genie> edit("config/database.yml")
```
The file contains placeholders for database configuration for each of the three environments: `dev`, `test` and `prod`. Our application runs in `dev` mode, and that's what we'll need to configure. Setup the `adapter:` key to `SQLite` and the `host:` to `db/dev.sqlite`. It should look like this:
```yaml
dev:
  adapter: SQLite
  database:
  host: db/dev.sqlite
  username:
  password:
  port:
  config:
```

You'll have to restart the Genie app so that the changes are loaded. Close the terminal window (or kill the Julia process). Then open a terminal in the app's root (or `cd` into the app's root). You can load a Genie app with:
```
$ bin/repl
```

Now that we're back into the app's environment, with the database configured, let's allow Genie to set things up. This needs to be run only once, after we've configured a new database:
```julia
genie> Genie.REPL.db_init()
```
The `db_init` function creates the database, if it does not exist, at `db/dev.sqlite`. And then creates a new table within the database -- this table, called `schema_migrations`, is used for storing database versioning and schema management.

## Working with resources
The concept of resource is central to Genie apps. A resource is a "thing" - a business object which is accessible over the internet. Such resources can be created, read, updated and deleted (in what is called a CRUD workflow).

In order to implement a complete CRUD workflow, the full MVC stack is involved. We'll need routing, controller files, models (and the underlying database table), views -- and optionally, model data validators and controller access rules. But don't worries, we don't need to create all these files by hand: we have a powerful genie sidekick.

We can ask Genie to create a new _chirp_ resource -- which will represent a user message in our system.
```julia
genie> Genie.REPL.new_resource("chirp")

info: New model created at /Users/adrian/Dropbox/Projects/chirper/app/resources/chirps/Chirps.jl
info: New migration created at /Users/adrian/Dropbox/Projects/chirper/db/migrations/20180312172359808_create_table_chirps.jl
info: New ChirpsValidator.jl created at /Users/adrian/Dropbox/Projects/chirper/app/resources/chirps/ChirpsValidator.jl
info: New chirps_test.jl created at /Users/adrian/Dropbox/Projects/chirper/test/unit/chirps_test.jl
info: New ChirpsController.jl created at /Users/adrian/Dropbox/Projects/chirper/app/resources/chirps/ChirpsController.jl
info: New ChirpsChannel.jl created at /Users/adrian/Dropbox/Projects/chirper/app/resources/chirps/ChirpsChannel.jl
info: New authorization.yml created at /Users/adrian/Dropbox/Projects/chirper/app/resources/chirps/authorization.yml
info: New chirps_test.jl created at /Users/adrian/Dropbox/Projects/chirper/test/unit/chirps_test.jl
```
Genie creates the full range of MVC files. We'll cover each one of them as we'll use them to develop our app.

## Database versioning with migrations
SearchLight, Genie's ORM layer comes with database migration functionality. Migrations are scripts used to change the database -- by creating and altering tables, for example. These scripts are put under version control and shared with the whole development team. Also, using the migration's API, the changes can be managed properly (for instance, they need to be run in the proper order).

Asking Genie to create a new resource has added a new migration. It was called {timestamp}_{migration_name}.jl -- for example, `20180312172359808_create_table_chirps.jl`. Genie's migrations have one of two states: up or down. These are defined in two functions with the same name. The `up` function contains the functionality for modifying the database -- while the `down` function has code to revert the changes. For instance, if `up()` has code to create a table, `down()` will have code to drop the table. Conversely, a migration is said to be `up` if it's `up()` function has been run -- and `down` if not. Genie/SearchLight keeps track of what migrations are up and which are down.
```julia
genie> Migration.status()
+===+==========================================+
|   |                    Module name & status  |
|   |                               File name  |
+===+==========================================+
|   |                  CreateTableChirps: DOWN |
| 1 | 20180312172359808_create_table_chirps.jl |
+---+------------------------------------------+
```
As expected, the migration is `DOWN`. We need to write the code for `up()` and `down()` and then run the migration. All the migrations files are stored within the `db/migrations` folder. Let's edit our migration (your migration will have a different name, because of the different timestamp):
```julia
genie> edit("db/migrations/20180312172359808_create_table_chirps.jl")
```
You will see that the file already comes filled up with some sensible defaults. It's to early to understand all the details of our app, so let's not overthink it. But for sure, our chirps need to have a content, some text. And a timestamp -- because we'll want to show them in a timeline. Make sure the `up()` function looks like this then save the file:
```julia
function up()
  create_table(:chirps) do
    [
      column_id()
      column(:content, :text)
      column(:created_at, :datetime)
    ]
  end

  add_index(:chirps, :created_at)
end
```
Here we have a call to the `create_table` function, passing in the name of the table, "chirps" (by convention, table names are pluralised). The `column_id` function creates a `primary_key`, auto-incrementable. While `column` creates a new column - the first argument is the name of the column, the second is the type. Finally, `add_index` will created an index on the `created_at` column. Now we can run our migration:
```julia
genie> Migration.up()

info: SQL QUERY: CREATE TABLE chirps (id INTEGER PRIMARY KEY , content TEXT , created_at DATETIME )
info: SQL QUERY: CREATE  INDEX chirps__idx_created_at ON chirps (created_at)
info: Executed migration CreateTableChirps up
```

## Setting up the `Chirp` model
Another file created by Genie's resource generator is the `Chirps.jl` model. It can be found at `app/resources/chirps/Chirps.jl`. It contains the definition of the `Chirp` `type`/`struct` -- and it designed to hold all the functions related to the manipulation of `Chirp` types. The `Chirp` `struct` is meant to model/map the underlying `chirps` table. Genie/SearchLight provides a rich API for CRUD operations against the table by working with the `struct` only. But first we need to set it up.

All we want to do at this point is map the columns of the `chirps` table to fields of the `Chirp` `struct`. Open the file in your editor (`genie> edit("app/resources/chirps/Chirps.jl")`) and edit it as follows:
```julia
# ... code here ...

### fields
id::Nullable{SearchLight.DbId}
content::String                       # add this
created_at::DateTime                  # and this
# ... code here ...

# ... code here ...
Chirp(;
  id = Nullable{SearchLight.DbId}(),
  content = "",                       # add this
  created_at = Dates.now()            # and this
# ... code here ...
) = new("chirps", "id",
        id,
        content,                      # add this
        created_at                    # and this
# ... code here ...
)
```
In the first section we define the fields corresponding to the columns (same name). In the second, we update the constructor with default values for each field. You can try it now:
```julia
genie> using Chirps

genie> chirp = Chirp(content = "foo bar")
genie>
Chirps.Chirp
+============+=========================================+
|        key |                                   value |
+============+=========================================+
|    content |                                 foo bar |
+------------+-----------------------------------------+
| created_at |                 2018-03-12T19:05:59.515 |
+------------+-----------------------------------------+
|         id | Nullable{Union{Int32, Int64, String}}() |
+------------+-----------------------------------------+
```
We can persist it to the database with:
```julia
genie> SearchLight.save!!(chirp)

info: SQL QUERY: INSERT  INTO chirps ( "content", "created_at" ) VALUES ( 'foo bar', '2018-03-12T19:05:59.515' )
info: SQL QUERY: ; SELECT CASE WHEN last_insert_rowid() = 0 THEN -1 ELSE last_insert_rowid() END AS id
info: 1×1 DataFrames.DataFrame
│ Row │ id │
├─────┼────┤
│ 1   │ 1  │


info: SQL QUERY: SELECT "chirps"."id" AS "chirps_id", "chirps"."content" AS "chirps_content", "chirps"."created_at" AS "chirps_created_at" FROM "chirps" WHERE ("chirps"."id" = 1) ORDER BY chirps.id ASC LIMIT 1
info: 1×3 DataFrames.DataFrame
│ Row │ chirps_id │ chirps_content │ chirps_created_at       │
├─────┼───────────┼────────────────┼─────────────────────────┤
│ 1   │ 1         │ foo bar        │ 2018-03-12T19:05:59.515 │

genie>
Chirps.Chirp
+============+==========================================+
|        key |                                    value |
+============+==========================================+
|    content |                                  foo bar |
+------------+------------------------------------------+
| created_at |                  2018-03-12T19:05:59.515 |
+------------+------------------------------------------+
|         id | Nullable{Union{Int32, Int64, String}}(1) |
+------------+------------------------------------------+
```
Our chirp has been saved to the database.

## Listing chirps
Now that we're able to create, persist and read chirps, let's display them on the website. Open the routes file (`config/routes.jl`) and append a new route:
```julia
route("/chirps", ChirpsController.index)
```
For this to work, don't forget to declare that you're `using ChirpsController`. Now, edit `app/resources/chirps/ChirpsController.jl` and add a placeholder `index` function:
```julia
function index()
  "List chirps here"
end
```
Make sure that the web server is running (if not, start it with `genie> AppServer.startup()`) and visit `http://localhost:8000/chirps`. You should see the message "List chirps here".

Great! If only this was more useful. No worries, it's easy.

Go back to the `ChirpsController.jl` file and make sure the `index()` function reads:
```julia
function index()
  chirps = SearchLight.find(Chirp)
  respond_with_html(:chirps, :index, chirps = chirps)
end
```
In order for this to work, you also need to update the `using` command:
```julia
using App, SearchLight, Chirps
```

Then, create a new view file in `app/resources/chirps/views`, called `index.flax.html` and edit its content as follows:
```julia
<h1>Chirps</h1>
<ul>
  <% @foreach(@vars(:chirps)) do ch %>
    <li>
      $(ch.content)
    </li>
  <% end %>
</ul>
```

Just to confirm that everything works well, let's add another chirp to the database:
```julia
genie> Chirp(content = "The quick fox") |> SearchLight.save!!
```
Refreshing `http://localhost:8000/chirps` should show the new chirp.

## Generating test data with database seeding
Creating and persisting chirps through Genie's REPL is straightforward -- but not very effective if we need to generate a lot of test data. For this reason SearchLight comes with a `DatabaseSeeding` module which makes it very easy to generate and persist any number of models.

By convention, `DatabaseSeeding` invokes the model's `random` method. Which means we need to add a new `random()` function to the `Chirps` module. We'll also need a way to generate random content for our chirps. We can do this by using the `Faker` package. Please add the `Faker` package now.

Now, edit `app/resources/chirps/Chirps.jl` and add this function to the module:
```julia
function random()
  Chirp(content = Faker.sentence())
end
```
While we're at it, don't forget to declare that we're `using Faker`.

Finally, back to Genie's REPL, run:
```julia
genie> using DatabaseSeeding
genie> DatabaseSeeding.random_seeder(Chirps)
```
This will create ten random `Chirps` and will persist them. Let's add a few more, say, 100.
```julia
genie> DatabaseSeeding.random_seeder(Chirps, 100)
```
Awesome!

If you reload the `/chirps` page you'll see a long list of literally random sentences, lorem-ipsum style. And right off the bat we can tell that we're going to need to paginate these results.

## Paginating lists
In order to implement pagination we'll need to know how many chirps we have in total -- and decide how many chirps we want to display per page. In order to get the total number of chirps, we need to perform a `count` query against the `chirps` table. With SearchLight we do it like this:
```julia
total_chirps = SearchLight.count(Chirp)
```
As for the chirps per page, let's decide on 20:
```julia
const CHIRPS_PER_PAGE = 20
```

Next we need to select only the number of chirps we need, using the `limit` and `offset` parameters for the SearchLight query:
```julia
chirps = SearchLight.find(Chirp, SQLQuery(limit = CHIRPS_PER_PAGE, offset = Int(@params(:page, 0)) * CHIRPS_PER_PAGE, order = "created_at DESC"))
```
For refining our `find` we pass a second parameter, a `SQLQuery` object. This sets a select limit of 20 and an offset of `:page` multiplied by `CHIRPS_PER_PAGE`. The `@params` collection contains all the request parameters; that is, all the GET and POST variables. In this case, we'll send the `:page` param over GET, as `?page=`. In order to access request parameters we use `@params(:var_name)`. But in this case, it's possible that the `:page` param is not sent - so we use `@params(:var_name, default_value)` in order to use 0 as the default value. We also said that we want to order the chirps by newest first, and we're doing that using the `created_at` field we setup especially for this.

We also need to pass the extra value we computed to the view layer. The `ChirpsController.index` function should now look like this:
```julia
const CHIRPS_PER_PAGE = 20

function index()
  total_chirps = SearchLight.count(Chirp)
  chirps = SearchLight.find(Chirp, SQLQuery(limit = CHIRPS_PER_PAGE, offset = Int(@params(:page, 0)) * CHIRPS_PER_PAGE, order = "created_at DESC"))
  respond_with_html(:chirps, :index, chirps = chirps, chirps_per_page = CHIRPS_PER_PAGE, total_chirps = total_chirps)
end
```

Next we need to add the logic to render the links for each page. We want to generate a list of links that look like `/chirps?page=1`, `/chirps?page=2`, etc. We could do it in the view file (in `index.flax.html`) but that would be very bad practice. The views should not contain complex logic. For such cases we should use a view helper method.

### Working with ViewHelpers
In the `app/helpers` folder you'll find the `ViewHelper.jl` file. Please open it in the editor and append this to the `ViewHelper` module:
```julia
function chirps_pagination(total_chirps::Int, chirps_per_page::Int) :: String
  total_chirps < chirps_per_page && return ""
  mapreduce(*, [Int(i) for i in 0:floor(total_chirps/chirps_per_page)]) do i
    """<a href="/chirps?page=$i">$(i+1)</a> """
  end
end
```
Also, don't forget to `export chirps_pagination`.

Finally, go to the `index.flax.html` view file and add this at the bottom:
```html
<div>
  <% chirps_pagination(@vars(:total_chirps), @vars(:chirps_per_page)) %>
</div>
```

Reload the `/chirps` page. You should now see the navigation component -- and the list of chirps only showing 20 chirps at a time. Try out the page navigation.

## Using forms
Our app is working great so far, but we really need a way to create chirps from the web page. We need a form!

The form will stay on a new page, at `/chirps/new` -- let's open `routes.jl` and add it:
```julia
route("/chirps/new", ChirpsController.new)
```

In `ChirpsController` add a `new()` function:
```julia
function new()
  respond_with_html(:chirps, :new)
end
```

And let's add the view file as `new.flax.html` under the `app/resources/chirps/views` folder:
```html
<h1>New chirp</h1>

<form action="/chirps" method="POST">
  <textarea name="content" placeholder="Chirp content"></textarea>
  <br />
  <input type="submit" value="Chirp!" />
</form>
```
If you are familiar with HTML, it should be crystal clear: we have a form with POSTs data to `/chirps/create`. And a textarea with the name `content`.

Next we need to add the route for `/chirps/create`:
```julia
route("/chirps", ChirpsController.create, method = POST)
```
Notice the extra keyword argument, `method = POST` -- which defines the route for POST requests.

Finally, we need to define the function in the controller. Let's try a first basic iteration:
```julia
function create()
  chirp = Chirp(content = @params(:content))
  SearchLight.save(chirp) ? "OK" : "Failed"
end
```
We look for the `content` variable in the request params and create a new `Chirp` object. Then if we save it successfully, we display "OK", otherwise "Failed".

Go ahead and try it: go to `http://localhost:8000/chirps/new` and submit the form.

## Handling forms workflows
If your code is correct you've just added a new chirp and you see "OK" on the page. Things have worked but we're not done yet.

If the chirp is successfully created, we should redirect the user to the list of chirps with a success message. If the request failed, we should show the form again, with the previous submitted data already pre-filled and an error message. Let's do this.

The `new` and `create` functions should now look like this:
```julia
function new(chirp = Chirp(content = ""))
  respond_with_html(:chirps, :new, chirp = chirp)
end

function create()
  chirp = Chirp(content = @params(:content))
  if SearchLight.save(chirp)
    redirect_to(:get_chirps)
  else
    new(chirp)
  end
end
```
As discussed, if the chirp is successfully persisted, we `redirect_to` the chirps list. The URL for this page is `/chirps` -- and the request method is GET. If persisting the chirp fails, we invoke the `new` function. However, notice that we've extended the `new` method to accept a `chirp` param. If this method is invoked by Genie to handle the request, `chirp` will get the default value. If we invoke it, we pass the chirp with the values provided by the user. The `chirp` object is then forwarded into the view.

We need to extend our view so that it displays the values from the `chirp` variable.
```html
<h1>New chirp</h1>

<form action="$(link_to(:get_chirps))" method="POST">
  <textarea name="content" placeholder="Chirp content">$(@vars(:chirp).content)</textarea>
  <br />
  <input type="submit" value="Chirp!" />
</form>
```

### Reverse routing
In the controller we could have used `redirect_to("/chirps")`. Also, notice that we've changed the form's action to a call to `link_to(:get_chirps)`. Using hard coded URLs is a bad practice. If later on we decide to change the link, we have to update them throughout the whole app. Instead we use a feature that can be considered _reversed routing_: from a route, we generate the corresponding URL. The routes are referenced by name -- you can explicitly name a route by passing the keyword argument `named = :your_route_name`. If we don't name our routes, Genie will do it for us.

The default name of the route is composed of the method and URI parts. For example, if we route the URI `/foo/bar/baz` over POST, the route will be named `:post_foo_bar_baz`. Anyway, when in doubt, you can either explicitly name the routes and/or check with Genie:
```julia
genie> Router.print_named_routes()
+=================+=================================================================================+
|             key |                                                                           value |
+=================+=================================================================================+
|            :get |                     (("GET", "/", Router.#18), Dict(:with=>Dict{Symbol,Any}())) |
+-----------------+---------------------------------------------------------------------------------+
|     :get_chirps |   (("GET", "/chirps", ChirpsController.index), Dict(:with=>Dict{Symbol,Any}())) |
+-----------------+---------------------------------------------------------------------------------+
| :get_chirps_new | (("GET", "/chirps/new", ChirpsController.new), Dict(:with=>Dict{Symbol,Any}())) |
+-----------------+---------------------------------------------------------------------------------+
|    :post_chirps | (("POST", "/chirps", ChirpsController.create), Dict(:with=>Dict{Symbol,Any}())) |
+-----------------+---------------------------------------------------------------------------------+
```
This is the routes registry for our app so far. Notice that from the routes we can also push extra variables into @params using the `with` `Dict`.

## Using the `flash`
The `flash` is a temporary storage which allows us to pass a value from the current request to the next. Its main objective is to pass success or error messages across redirects. Let's use it to inform our user that the chirp was successfully added.

We need to add a new line in our `new` function to set the `flash`:
```julia
function create()
  chirp = Chirp(content = @params(:content))
  if SearchLight.save(chirp)
    flash("Your chirp was saved")       # this sets the flash
    redirect_to(:get_chirps)
  else
    new(chirp)
  end
end
```

And we also need to output the `flash` into the view:
```html
<h1>Chirps</h1>

<a href="$(link_to(:get_chirps_new))">Chirp in</a>
<br /><br />

<% output_flash(@params) %>

<ul>
  <% @foreach(@vars(:chirps)) do ch %>
    <li>
      $(ch.content)
    </li>
  <% end %>
</ul>

<div>
  <% ViewHelper.chirps_pagination(@vars(:total_chirps), @vars(:chirps_per_page)) %>
</div>
```
Your `index.flax.html` file should now look like the above. Notice the `<% output_flash(@params) %>` line which is responsible with displaying the `flash` value, if set. And as an added bonus, we've also included a link to the new chirp form.

Finally, we need to enable sessions as `flash` uses them to store the data. Sessions are not enabled by default. We turn them on in the `config/env/dev.jl` file, which is the settings file for the development environment. Our app is running in dev mode and these are the settings its using. In the `Settings` constructor, look for a line that says `session_auto_start = false` and set that to `true`. You'll need to restart the app by killing the current Julia process (Ctrl/Cmd + D) in the Genie REPL and then `$ bin/repl` in the terminal.

After you restart the app, once you successfully add a new chirp, you'll be redirected to the chirps list and the `flash` message will be displayed. If you refresh the list, the `flash` message will disappear.

## Validating model data
So far our app will gladly accept any kind of input. But a chirp without content -- or with a very short one -- won't be of any use. We need to make sure that the content of the chirps has a minimum length.

SearchLight models have built-in data validation functionality -- which can be coupled with the ViewHelper API to output the validation results. Our `Chirps` model already has a few commented out lines which we can use to enable validations.

Edit the `Chirps.jl` model file (in `app/resources/chirps`) and look for a line that says `### validator`. Uncomment the next line:
```julia
### validator
validator::ModelValidator
```

Next look for `### constructor` and edit the corresponding lines to look like this:
```julia
### constructor
Chirp(;
  id = Nullable{SearchLight.DbId}(),
  content = "",
  created_at = Dates.now(),

  validator = ModelValidator([                                # <-- validator
    ValidationRule(:content, ChirpsValidator.not_empty)       # <-- validator
  ])                                                          # <-- validator

  # belongs_to = [],
)
```

Finally we need to enable the validator within the `new()` call:
```julia
new("chirps", "id",
        id, content, created_at,
        validator                         # <-- validator
        # belongs_to, has_one, has_many,
)
```

The important bit here is `ValidationRule(:content, ChirpsValidator.not_empty)` -- the rest is just setting up the `Type`. Here we register a `ValidationRule` which states that the `content` field should be checked with the `ChirpsValidator.not_empty` function. Validation functions are expected to always return an instance of `ValidationResult`. A `ValidationResult` encodes a validation success (as `ValidationResult(valid)`) or a validation error. If it's a validation error, the `ValidationResult` object will also include details about the error: `ValidationResult(invalid, :not_empty, "should not be empty")`.

Let's add another `ValidationRule` requiring that the content of a Chirp is at least 20 characters long. Edit `app/resources/chirps/ChirpsValidator.jl` and add the following function definition:
```julia
function minimum_length(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
  length(getfield(m, field)) < 20 && return ValidationResult(invalid, :minimum_length, "should be at least 20 letters long")

  ValidationResult(valid)
end
```

We also need to register the corresponding `ValidationRule` in the `Chirps.jl` model:
```julia
validator = ModelValidator([
  ValidationRule(:content, ChirpsValidator.not_empty),
  ValidationRule(:content, ChirpsValidator.minimum_length)      # <-- add this
])
```

Now we can try it out in the REPL (you might have to restart the app to pick up the changes):
```julia
genie> using Chirps

genie> ch = Chirp(content = "")
genie>
Chirps.Chirp
+============+=========================================+
|        key |                                   value |
+============+=========================================+
|    content |                                         |
+------------+-----------------------------------------+
| created_at |                 2018-03-16T18:43:17.242 |
+------------+-----------------------------------------+
|         id | Nullable{Union{Int32, Int64, String}}() |
+------------+-----------------------------------------+


genie> Validation.validate!(ch)
genie> false

genie> Validation.errors(ch)
genie> Nullable{Array{Validation.ValidationError,1}}(Validation.ValidationError[
Validation.ValidationError
+===============+=====================+
|           key |               value |
+===============+=====================+
| error_message | should not be empty |
+---------------+---------------------+
|    error_type |           not_empty |
+---------------+---------------------+
|         field |             content |
+---------------+---------------------+
,
Validation.ValidationError
+===============+====================================+
|           key |                              value |
+===============+====================================+
| error_message | should be at least 20 letters long |
+---------------+------------------------------------+
|    error_type |                     minimum_length |
+---------------+------------------------------------+
|         field |                            content |
+---------------+------------------------------------+
])
```
We create a new `Chirp` object with invalid `content`. Then we call the `validate!` method -- it returns `false` indicating that the validation has failed. We can get the list of errors with `Validation.errors`.

Let's use this to validate chirps on our website. We need to add the validation check to our `ChirpsController`:
```julia
function create()
  chirp = Chirp(content = @params(:content))
  if Validation.validate!(chirp) && SearchLight.save(chirp)   # <-- validation here
    flash("Your chirp was saved")
    redirect_to(:get_chirps)
  else
    new(chirp)
  end
end
```

And enable the output of the errors in the view, in `new.flax.html`. Add the `<div>` element on the line under the `<textarea>`, like in the following snippet:
```html
<form action="$(link_to(:get_chirps))" method="POST">
  <textarea name="content" placeholder="Chirp content">$(@vars(:chirp).content)</textarea>
  <div><% output_errors(@vars(:chirp), :content) %></div>     
  <input type="submit" value="Chirp!" />
</form>
```
That's all! Try out the app, you should see the errors.

## Testing our app
