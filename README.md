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

Finally, now navigate to "http://localhost:8000" -- you should see the message "Hi there!".

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

Working with Genie in an interactive environment can be useful -- but usually we want to persist our application and reload it between sessions. One way to achieve that is to save it as an IJulia notebook and rerun the cells. However, you can get the most of Genie by working with Genie apps. A Genie app is an MVC web application which promotes the convention-over-configuration principle. Which means that by working with a few predefined files, within the Genie app structure, Genie can lift a lot of weight and massively improve development productivity. This includes automatic module loading and reloading, dedicated configuration files, logging, environments, code generators, and more.

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

### Loading your Julia code into the Genie app
If you have an existing Julia application or standalone codebase which you'd like to expose over the web through your Genie app, the easiest thing to do is to drop the files into the `lib/` folder. The `lib/` folder is automatically added by Genie to the `LOAD_PATH`.

You can also add folders under `lib/`, they will be recursively added to `LOAD_PATH`. Beware though that this only happens when the Genie app is initially loaded. Hence, an app restart might be required.

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
Adding your code to the `routes.jl` file or placing it into the `lib/` folder works great for small projects, where you want to quickly publish some features on the web. But for any larger projects we're better off we're better off using Genie's MVC structure. By employing the Module View Controller design pattern we can break our code in modules with clear responsabilities. Modular code is easier to write, test and maintain.

A Genie app is structured around the concept of "resources". A resource represents a business entity (something like a user, or a product, or an account) and maps to a bundle of files (controller, model, views, etc).

Resources live under `app/resources/`. For example, if we have a web app about "books", a "books/" folder would be placed in `app/resources/` and would contain all the files for publishing books on the web.

### Using Controllers
Controllers are used to orchestrate interactions between client requests, models (DB access), and views (response rendering). In a standard workflow a route points to a method in the controller -- which is responsible for building and sending the response.

Let's add a "books" controller. We could do it by hand -- but Genie comes with handy generators which will happily do the boring work for us.

#### Generate the Controller
Let's generate our `BooksController`:
```julia
genie> Genie.REPL.new_controller("Books")
[info]: New controller created at app/resources/books/BooksController.jl
```

Great! Let's edit `BooksController.jl` and add something to it. For example, a function which returns somf of Bill Gate's recommended books would be nice. Make sure that `BooksController.jl` looks like this:
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
    <h1>Bill's Gates list of recommended books</h1>
    <ul>
      $( mapreduce(b -> "<li>$(b.title) by $(b.author)", *, BillGatesBooks) )
    </ul>
  "
end

end
```

That should be clear enough -- just a plain Julia module. Now, let's expose our `billgatesbooks` method on the web. We need to add a new route which points to it:
```julia
# config/routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```

That's all! If you now visit `http://localhost:8000/bgbooks` you'll see Bill's Gates list of recommended books.

### Adding views
However, putting HTML into the controllers is a bad idea: that should stay in the view files. Let's refactor our code to use views.

The views used for rendering a resource should be placed inside a "views/" folder, within that resource's own folder. So in our case, we will add an `app/resources/books/views/` folder. Just go ahead and do it, Genie does not provide a generator for this simple task.

#### Naming views
Usually each controller method will have its own rendering logic -- hence, its own view file. Thus, it's a good practice to name the view files just like the methods, so we can keep track of where they're used.

At the moment, Genie supports HTML and Markdown view files. Their type is identified by file extension so that's an important part. The HTML views use a ".jl.html" extension while the Markdown files go with ".jl.md".

#### HTML views
All right then, let's add our first view file for the `BooksController.billgatesbooks` method. Let's add an HTML view. With Julia:
```julia
julia> touch("app/resources/books/views/billgatesbooks.jl.html")
```

Genie supports a special type of HTML view, where we can embed Julia code. These are high performance compiled views. They are not parsed as strings: instead, the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file. Hence, the first time you load a view or ofter you change one, you might notice a certain delay -- it's the time needed to generate and compile the view. On next runs (especially in production) it's blazing fast!

Now all we need to do is to move the HTML code out of the controller and into the view:
```html
<!-- billgatesbooks.jl.html -->
<h1>Bill's Gates list of recommended books</h1>
<ul>
   <%
      @foreach(@vars(:books)) do book
         "<li>$(book.title) by $(book.author)"
      end
   %>
</ul>
```

As you can see, it's just plain HTML with embedded Julia. We can add Julia code either by using the `<% ... %>` code block tags. Or by plain string interpolation with `$(...)`. It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, your Julia code _must return a string_ as the result, so that the output of your computation comes up on the page.

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

The `html!` function takes as its arguments:
* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file)
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out
* and finally, we pass the values we want to expose in the view, as keyword arguments. In this scenario, the `books` keyword argument -- which will be available in the view file under `@args(:books)`.

That's it -- our refactored app should be ready!

#### Markdown views
Markdown views work similar to HTML views -- employing the same embedded Julia functionality. Here is how you can add a Markdown view for our `billgatesbooks` function.

First, create the corresponding view file, using the `.jl.md` extension. Maybe with:
```julia
julia> touch("app/resources/books/views/billgatesbooks.jl.md")
```

Now edit the file and make sure it looks like this:
```md
<!-- app/resources/books/views/billgatesbooks.jl.md -->
# Bill's Gates list of recommended books
$(
   @foreach(@vars(:books)) do book
      "* $(book.title) by $(book.author)"
   end
)
```

Notice that Markdown views do not support the embedded Julia tags `<% ... %>`. Only string interpolation `$(...)` is accepted.

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

### Rendering JSON
A very common use case for web apps is to serve as backends for RESTful APIs. For this cases, JSON is the preferred data format. You'll be happy to hear that Genie has built in support for JSON responses.

Let's add an endpoint for our API -- which will render Bill Gate's books as JSON.

We can start in the `routes.jl` file, by appending this:
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

Keep in mind that you're free to organize the code as you see fit -- not necessarily like this. It's just one way to do it.

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

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone. The solution is to, again, use views, to fully control how we render our data -- and decouple the data structure from its rendering on the web.

#### JSON views
Genie has support for JSON views -- these are plain Julia files which have the ".json.jl" extension. Let's add one in our `views/` folder:
```julia
julia> touch("app/resources/books/views/billgatesbooks.json.jl")
```

We can now create a proper response. Put this in the newly created view file:
```julia
# app/resources/books/views/billgatesbooks.json.jl
Dict(
  "Bill's Gates list of recommended books" => @vars(:books)
)
```

Final step, instructing `BooksController` to render the view:
```julia
function billgatesbooks()
  json!(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
end
```
This should hold no surprises -- the `json!` function is similar to the `html!` one we've seen before.

That's all -- everything should work!

## Accessing databases with SeachLight models
... Coming up ... 

---

## Next steps
If you want to learn more about Genie you can
* check out the API docs (out of date -- updates coming soon)
  * [Genie Web Framework](http://geniejl.readthedocs.io/en/latest/build/)
  * [SearchLight ORM](http://searchlightjl.readthedocs.io/en/latest/build/)
  * [Flax Templates](http://flaxjl.readthedocs.io/en/latest/build/)
* read the guides (coming soon)
* take a look at the slides for the Genie presentation at the 2017 JuliaCon [JuliaCon 2017 Genie Slides](https://github.com/essenciary/JuliaCon-2017-Slides/tree/master/v1.1)
* visit [genieframework.com](http://genieframework.com) for more resources


## Acknowledgements
* Genie uses a multitude of packages that have been kindly contributed by the Julia community.
* The awesome Genie logo was designed by my friend Alvaro Casanova (www.yeahstyledg.com).
