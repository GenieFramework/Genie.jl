### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ b2667ebb-10d4-4233-804d-589f3d108dc6
# hideall 

using Revise

# ╔═╡ 1104aef8-6de4-4fb0-b0d1-6e85df6e86e0
# hideall

using Genie

# ╔═╡ de3d681a-424a-11ec-0a26-574b0c85d733
md"""
# Working with Genie apps (projects)

Working with Genie in an interactive environment can be useful – but usually we want to persist the application and reuse it between sessions. One way to achieve this is to save it as an IJulia notebook and rerun the cells.

However, you can get the best of Genie by working with Genie apps. A Genie app is a MVC (Model-View-Controller) web application which promotes the convention-over-configuration principle. By working with a few predefined files, within the Genie app structure, the framework can lift a lot of weight and massively improve development productivity. But following Genie's workflow, one instantly gets, out of the box, features like automatic module loading and reloading, dedicated configuration files, logging, support for environments, code generators, caching, support for Genie plugins, and more.

```julia
julia> using Pkg
julia> Pkg.add("Genie")
```

In order to create a new Genie app, we need to run `Genie.newapp($app_name)`:
"""

# ╔═╡ dfce7e49-2848-4656-8880-386cfcd99ffe
md"""

```julia
julia> using Genie

julia> Genie.newapp("MyGenieApp")
```

"""

# ╔═╡ c2e80b10-502e-46c8-b802-ee9956b63fcc
# hideall

Genie.newapp("MyGenieApp")

# ╔═╡ 628696ba-4d35-4be9-9ffd-e1e1fd583449
md"""
Upon executing the command, Genie will:

* make a new dir called `MyGenieApp` and `cd()` into it,
* install all the app's dependencies,
* create a new Julia project (adding the `Project.toml` and `Manifest.toml` files),
* activate the project,
* automatically load the new app's environment into the REPL,
* start the web server on the default Genie port (port 8000) and host (127.0.0.1).

At this point you can confirm that everything worked as expected by visiting <http://127.0.0.1:8000> in your favourite web browser. You should see Genie's welcome page.

Next, let's add a new route. Routes are used to map request URLs to Julia functions. These functions provide the response that will be sent back to the client. Routes are meant to be defined in the dedicated `routes.jl` file. Open `MyGenieApp/routes.jl` in your editor or run the following command (making sure that you are in the app's directory):
"""

# ╔═╡ 2ee6a844-c14b-4ee1-a444-e883ade1e0ec
md"""

```julia
julia> edit("routes.jl")
```
"""

# ╔═╡ a7e80773-02e0-4352-b04e-c84b6a995ffe
md"""
Append this at the bottom of the `routes.jl` file and save it:
"""

# ╔═╡ ea12f1c9-b48e-4575-be03-d9ecc65062e9
md"""

```julia
# routes.jl
route("/hello") do
  "Welcome to Genie!"
end
```

"""

# ╔═╡ a0d85997-d167-4c8b-a2f2-e50ef4c2193e
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """using Genie.Router

route("/") do
  serve_static_file("welcome.html")
end

route("/hello") do
  "Welcome to Genie!"
end""");

# ╔═╡ d7cb397d-3042-4858-baf3-833f3c70083f
md"""
We are using the `route` method, passing in the "/hello" URL and an anonymous function which returns the string "Welcome to Genie!". What this means is that for each request to the "/hello" URL, our app will invoke the route handler function and respond with the welcome message.

Visit <http://127.0.0.1:8000/hello> for a warm welcome!

"""

# ╔═╡ 11659bac-808b-48be-be7c-fff4b2f262c5
md"""
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
"""

# ╔═╡ 9363139c-17b1-446b-b7bd-c72bf18bf8f2
md"""
Let's generate our `BooksController`:
"""

# ╔═╡ 2141f87a-9beb-43d9-8129-5b17dc3400ab
md"""

```julia
julia> Genie.newcontroller("Books")
[info]: New controller created at ./app/resources/books/BooksController.jl

```

"""

# ╔═╡ 29c0bdfa-a7dc-44c6-9e97-03ab9883828b
# hideall

begin
	bcontroller = true;
	Genie.newcontroller("Books");
end;

# ╔═╡ adece903-915b-4f77-997d-e5fe5e49ebd7
# hideall

begin
	bcontroller
	using BooksController
end

# ╔═╡ e879fd0d-4399-4ef9-8fdf-75cc7d00bb29
md"""
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

"""

# ╔═╡ f63d7226-ffcc-4402-bb2d-37cfe2d64593
# hideall

begin
	bcontroller;
	controllerPath = "$(dirname(pwd()))/MyGenieApp/app/resources/books/BooksController.jl";
end;

# ╔═╡ 09764303-330e-4c47-92ed-cb6ce13d629d
# hideall

begin
	bcontroller
	write(controllerPath, """module BooksController

using Genie.Renderer.Html

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
	\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
  </ul>
  "
end

function billgatesbooks_view()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end
end""");
end;

# ╔═╡ fdaceba9-6d8e-4b5a-b654-7a73c7dc92d6
md"""
Our controller is just a plain Julia module where we define a `Book` type/struct and set up an array of book objects. We then defined a function, `billgatesbooks`, which returns an HTML string, with a `H1` heading and an unordered list of all the books. We used an array comprehension to iterate over each book and render it in a `<li>` element. The elements of the array are then concatenated using the splat `...` operator.
The plan is to map this function to a route and expose it on the internet.

#### Checkpoint

Before exposing it on the web, we can test the function in the REPL:

"""

# ╔═╡ 6ba091fe-876c-45d5-8e1c-5963ae95686f
md"""

```julia
julia> using BooksController

```

"""

# ╔═╡ e96e7baf-a1fa-4662-b3f4-885b4810592d
md"""

```julia
julia> BooksController.billgatesbooks()
```

The output of the function call should be a HTML string which looks like this: 
"""

# ╔═╡ 19e78a3c-1f67-40fb-9863-c3155bed1136
md"""

```html
"\n  <h1>Bill Gates' list of recommended books</h1>\n  <ul>\n    <li>The Best We Could Do by Thi Bui</li><li>Evicted: Poverty and Profit in the American City by Matthew Desmond</li><li>Believe Me: A Memoir of Love, Death, and Jazz Chickens by Eddie Izzard</li><li>The Sympathizer by Viet Thanh Nguyen</li><li>Energy and Civilization, A History by Vaclav Smil</li>\n  </ul>\n"
```
"""

# ╔═╡ 06ec4ef2-b262-42f7-baa4-c2b7e1dbe4f8
md"""

Please make sure that it works as expected.

## Setup the route

Now, let's expose our `billgatesbooks` method on the web. We need to add a new `route` which points to it. Add these to the `routes.jl` file:

```julia
# routes.jl
using Genie.Router
using BooksController

route("/bgbooks", BooksController.billgatesbooks)
```
"""

# ╔═╡ 50299fe8-6a8c-4121-8e20-7b0b83f66a65
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end""");

# ╔═╡ 5eca6084-5f1e-4727-831e-fa0e6547c214
md"""
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
      for_each(BillGatesBooks) do book
        Html.li() do
          book.title * " by " * book.author
        end
      end
    end
  ]
end

```

"""

# ╔═╡ 88985c2d-48e8-4b6b-925d-7cfa05518b9a
md"""
The `for_each` macro iterates over a collection and concatenates the output of each loop into the result of the loop. We'll talk about it more soon.
"""

# ╔═╡ 0cc74c5f-f700-416d-aa70-fd76682ad16f
md"""
## Adding Views

However, putting HTML into the controllers is a bad idea: HTML should stay in the dedicated view files and contain as little logic as possible. Let's refactor our code to use views instead.

The views used for rendering a resource should be placed inside the `views/` folder, within that resource's own folder structure.
So in our case, we will add an `app/resources/books/views/` folder. Just go ahead and do it, Genie does not provide a generator for this task:
"""

# ╔═╡ 93fd2d47-685a-4955-b594-5e0693913c98
md"""

```julia
julia> mkdir(joinpath("app", "resources", "books", "views"))
```
"""

# ╔═╡ a4c1b657-14d4-4035-aa7c-4ba78a6c9f34
# hideall

mkdir(joinpath("app", "resources", "books", "views"))

# ╔═╡ 52b7147b-a1b0-4ebf-a25c-a4fbde3f8090
md"""
We created the `views/` folder in `app/resources/books/`. We provided the full path as our REPL is running in the the root folder of the app. Also, we use the `joinpath` function so that Julia creates the path in a cross-platform way.

### Naming views

Usually each controller method will have its own rendering logic – hence, its own view file. Thus, it's a good practice to name the view files just like the methods, so that we can keep track of where they're used.

At the moment, Genie supports HTML and Markdown view files, as well as plain Julia. Their type is identified by file extension so that's an important part.
The HTML views use a `.jl.html` extension while the Markdown files go with `.jl.md` and the Julia ones by `.jl`.
"""

# ╔═╡ 3d305148-5bdc-41cf-814d-19b6e7319ff9
md"""
### HTML views

All right then, let's add our first view file for the `BooksController.billgatesbooks` method. Let's create an HTML view file. With Julia:
"""

# ╔═╡ bad5f961-cd90-4a63-ba5a-b873605f16b5
md"""

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.html"))
```
"""

# ╔═╡ 82c6343d-59d7-4e5b-ac0f-a12c2ac133e1
# hideall

touch(joinpath("$(dirname(pwd()))/MyGenieApp","app", "resources", "books", "views", "billgatesbooks.jl.html"));

# ╔═╡ 7777a8b8-4e62-43bf-920f-9e0a422e51b8
# hideall

viewPath2 = joinpath("$(dirname(pwd()))/MyGenieApp","app", "resources", "books", "views", "billgatesbooks.jl.html");

# ╔═╡ 0ec7409a-6bbc-4fdf-94b4-43f9aebe0bfb
md"""
Genie supports a special type of dynamic HTML view, where we can embed Julia code. These are high performance compiled views. They are _not_ parsed as strings: instead, **the HTML is converted to native Julia rendering code which is cached to the file system and loaded like any other Julia file**.
Hence, the first time you load a view, or after you change one, you might notice a certain delay – it's the time needed to generate, compile and load the view.
On next runs (especially in production) it's going to be blazing fast!

Now all we need to do is to move the HTML code out of the controller and into the view, improving it a bit to also show a count of the number of books. Edit the view file as follows (`julia> edit("app/resources/books/views/billgatesbooks.jl.html")`):

```html
<!-- billgatesbooks.jl.html -->
<h1>Bill Gates' top $(length(books)) recommended books</h1>
<ul>
  <% for_each(books) do book %>
    <li>$(book.title) by $(book.author)</li>
  <% end %>
</ul>
```
"""

# ╔═╡ 3dacfdaa-8016-4bab-bf31-882e2cd88b8b
# hideall

write(viewPath2, """<!-- billgatesbooks.jl.html -->
<h1>Bill Gates' top \$(length(books)) recommended books</h1>
<ul>
  <% for_each(books) do book %>
    <li>\$(book.title) by \$(book.author)</li>
  <% end %>
</ul>"""); 

# ╔═╡ ce610c99-79a0-4e08-97a8-2f9ed2766598
md"""
As you can see, it's just plain HTML with embedded Julia. We can add Julia code by using the `<% ... %>` code block tags – these should be used for more complex, multiline expressions. Or by using plain Julia string interpolation with `$(...)` – for simple values outputting.

To make HTML generation more efficient, Genie provides a series of helpers, like the above `for_each` macro which allows iterating over a collection, passing the current item into the processing function.

---
**HEADS UP**

**It is very important to keep in mind that Genie views work by rendering a HTML string. Thus, the Julia view code must return a string as its result, so that the output of the computation comes up on the page**. Given that Julia automatically returns the result of the last computation, most of the times this just flows naturally. But if sometimes you notice that the templates don't output what is expected, do check that the code returns a string (or something which can be converted to a string).


---

### Rendering views

We now need to refactor our controller to use the view, passing in the expected variables. We will use the html method which renders and outputs the response as HTML. Update the definition of the billgatesbooks function to be as follows:

```julia
# app/resources/books/BooksController.jl
module BooksController
using Genie.Renderer.Html

#= Previous Code =#

function billgatesbooks_view()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end
end
```

"""

# ╔═╡ b6eb4bbb-2fad-465c-897e-6442ac485c61
# hideall

begin
	bcontroller;
	write(controllerPath, """# app/resources/books/BooksController.jl
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
	  Book("The Sympathizer", "Viet Thanh Nguyen"),
	  Book("Energy and Civilization, A History", "Vaclav Smil")
	]

	function billgatesbooks()
	  "
	  <h1>Bill Gates' list of recommended books</h1>
	  <ul>
		\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
	  </ul>
	  "
	end

	function billgatesbooks_view()
	  html(:books, :billgatesbooks, books = BillGatesBooks)
	end

	end""");
end;

# ╔═╡ ba672e36-f0f3-472d-af0c-517c4d61d689
md"""
First, notice that we needed to add `Genie.Renderer.Html` as a dependency, to get access to the `html` method. As for the `html` method itself, it takes as its arguments the name of the resource, the name of the view file, and a list of keyword arguments representing view variables:

* `:books` is the name of the resource (which effectively indicates in which `views` folder Genie should look for the view file -- in our case `app/resources/books/views`);
* `:billgatesbooks` is the name of the view file. We don't need to pass the extension, Genie will figure it out since there's only one file with this name;
* and finally, we pass the values we want to expose in the view, as keyword arguments.

Next, we again add a route to `routes.jl`:

```julia
# routes.jl
using BooksController

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end
```
"""

# ╔═╡ 6ae6af95-6f00-480d-bf78-de1d8bf2a38b
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end""");

# ╔═╡ 32313d61-8200-4597-aa50-7bf1ced975eb
md"""

That's it – our refactored app including a layout and a new view should be ready! You can try it out for yourself at <http://localhost:8000/bgbooks_view>.
"""

# ╔═╡ 13addf69-7308-4652-9ada-d97040da9f03
md"""
### Markdown views

Markdown views work similar to HTML views – employing the same embedded Julia functionality. Here is how you can add a Markdown view for our `billgatesbooks...()` functions.

First, create the corresponding view file, using the `.jl.md` extension. Maybe with:
"""

# ╔═╡ 76509397-be50-4b27-b72f-548964856402
md"""

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.jl.md"))
```
"""

# ╔═╡ f9787fca-1aad-46f4-9676-5e17b0ad7f09
# hideall 
begin
	mdp = true;
	viewPath4 = joinpath("$(dirname(pwd()))/MyGenieApp/","app", "resources", "books", "views", "billgatesbooks.jl.md");
end;

# ╔═╡ d29af1bd-4da0-459b-ab65-da31933ee77c
# hideall

begin
	mdp;
	touch(viewPath4);
end;

# ╔═╡ fa9c6f04-81c8-417a-a140-adb0dea442b1
md"""
Now edit the file and make sure it looks like this:

```md
<!-- app/resources/books/views/billgatesbooks.jl.md -->
# Bill Gates' $(length(books)) recommended books

$(
  for_each(books) do book
    "* $(book.title) by $(book.author) \n"
  end
)
```
"""

# ╔═╡ 7dd69c90-1d40-4bef-aa69-30acd53209d2
# hideall

begin
	mdp;
	write(viewPath4, """<!-- app/resources/books/views/billgatesbooks.jl.md -->
	# Bill Gates' \$(length(books)) recommended books

	\$(
	  for_each(books) do book
		"* \$(book.title) by \$(book.author) \n"
	  end
	)""");
end;

# ╔═╡ 74b18c8c-7751-4d53-a83d-efeb7c03cb8f
md"""
Notice that Markdown views do not support Genie's embedded Julia tags `<% ... %>`. Only string interpolation `$(...)` is accepted, but it works across multiple lines.

If you reload the page now, however, Genie will still load the HTML view. The reason is that, _if we have only one view file_, Genie will manage.
But if there's more than one, the framework won't know which one to pick. It won't error out but will pick the preferred one, which is the HTML version.

It's a simple change in the `BookiesController`: we have to explicitly tell Genie which file to load, extension and all:

```julia
# BooksController.jl
function billgatesbooks_view_md()
  html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
end
```


```julia
# routes.jl
route("/bgbooks_view_md") do
  BooksController.billgatesbooks_view_md()
end
```
"""

# ╔═╡ 6f363e5c-dcec-4f5e-bcac-409356b873de
# hideall

begin
	bcontroller
	write(controllerPath, """# app/resources/books/BooksController.jl
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
	  Book("The Sympathizer", "Viet Thanh Nguyen"),
	  Book("Energy and Civilization, A History", "Vaclav Smil")
	]

	function billgatesbooks()
	  "
	  <h1>Bill Gates' list of recommended books</h1>
	  <ul>
		\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
	  </ul>
	  "
	end

	function billgatesbooks_view()
	  html(:books, :billgatesbooks, books = BillGatesBooks)
	end
	
	function billgatesbooks_view_admin()
		html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
	end

	function billgatesbooks_view_md()
		html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
	end
	
	end""");
end;

# ╔═╡ 24462235-7bc4-4de0-b377-ab038e4b3da3
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end
	
route("/bgbooks_view_admin") do
  BooksController.billgatesbooks_view_admin()
end

route("/bgbooks_view_md") do
  BooksController.billgatesbooks_view_md()
end""");

# ╔═╡ bcf0085c-86b3-4c38-96e2-315346df552c
md"""
you can check the results of markdown view on: <http://127.0.0.1:8000/bgbooks_view_md>

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

If you reload the page at <http://localhost:8000/bgbooks_view> you will see the new heading.
"""

# ╔═╡ 204c774c-d1e7-4e01-bd7a-ae67ed151584
md"""
But we don't have to stick to the default; we can add additional layouts. Let's suppose that we have, for example, an admin area which should have a completely different theme.
We can add a dedicated layout for that:
"""

# ╔═╡ 3e61a74b-e96b-4238-a898-07c0e71c920c
md"""

```julia
julia> touch(joinpath("app", "layouts", "admin.jl.html"))
"app/layouts/admin.jl.html"
```
"""

# ╔═╡ b3b1eb3d-f098-4934-ba23-10cd9ce8887f
# hideall

begin
	admin = true;
	viewPath3 = joinpath("$(dirname(pwd()))/MyGenieApp","app", "layouts", "admin.jl.html");
end;

# ╔═╡ 3972b319-95ae-48cd-9910-a8e17b9afbdf
# hideall

begin
	admin;
	touch(viewPath3);
end;

# ╔═╡ 1b96a87b-2a2e-4a2a-9410-ef6181db13a2
md"""
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
```"""

# ╔═╡ 87c9d856-18bd-4f66-9c07-d0ac8dd88b7c
# hideall

begin
	admin;
	write(viewPath3, """<!-- app/layouts/admin.jl.html -->
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
	""");
end;

# ╔═╡ 86c06852-d381-497a-9348-78b87368867a
md"""
If we want to apply it, we must instruct our `BooksController` to use it. The `html` function takes a keyword argument named `layout`, for the layout file.
Update the list of `billgatesbooks_view()` functions and the routes with these:
"""

# ╔═╡ d70da414-0002-466e-89d3-a60a94d5dae2
md"""
```julia
# BooksController.jl
function billgatesbooks_view()
  html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
end
```
"""

# ╔═╡ b6f5e3f2-34a7-4ffa-9636-88b4bb03e555
# hideall

begin
	bcontroller;
	write(controllerPath, """# app/resources/books/BooksController.jl
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
	  Book("The Sympathizer", "Viet Thanh Nguyen"),
	  Book("Energy and Civilization, A History", "Vaclav Smil")
	]

	function billgatesbooks()
	  "
	  <h1>Bill Gates' list of recommended books</h1>
	  <ul>
		\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
	  </ul>
	  "
	end

	function billgatesbooks_view()
	  html(:books, :billgatesbooks, books = BillGatesBooks)
	end
	
	function billgatesbooks_view_admin()
		html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
	end

	end""");
end;

# ╔═╡ 9cec384c-6ae3-4dd4-b2c8-8ad8e919e92f
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end
	
route("/bgbooks_view_admin") do
  BooksController.billgatesbooks_view_admin()
end""");

# ╔═╡ f9f12618-d00a-4a5a-9569-3540d7ba7515
md"""
Reload the page and you'll see the new heading.
"""

# ╔═╡ 28d65796-dfd5-4dba-b8dd-4d4c08e75e18
md"""
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
"""

# ╔═╡ 40daa02f-2fd8-4f29-88ec-b229fe59025b
md"""
### Rendering JSON views

A common use case for web apps is to serve as backends for RESTful APIs. For this cases, JSON is the preferred data format. You'll be happy to hear that Genie has built-in support for JSON responses. Let's add an endpoint for our API – which will render Bill Gates' books as JSON.

We can start in the `routes.jl` file, by appending this

```julia
route("/api/v1/bgbooks_view_json") do
  BooksController.API.billgatesbooks_view_json()
end
```

"""

# ╔═╡ 5ced7f6e-e84a-4cbf-9990-6cb3830362d5
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end
	
route("/bgbooks_view_admin") do
  BooksController.billgatesbooks_view_admin()
end

route("/bgbooks_view_md") do
  BooksController.billgatesbooks_view_md()
end

route("/api/v1/bgbooks_view_json") do
  BooksController.API.billgatesbooks_view_json()
end""");

# ╔═╡ 834850bb-fc3e-44b6-8dd8-32adb93ddcae
md"""

Next, in `BooksController.jl`, append the extra logic at the end of the file, before the closing end. The whole should look like this:


```julia

module BooksController

using Genie
using Genie.Renderer.Html

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

function billgatesbooks_view()
  html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
end

function billgatesbooks_view_md()
	html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
end

module API
using ..BooksController
using Genie.Renderer.Json

function billgatesbooks_view_json()
  json(BooksController.BillGatesBooks)
end

end # Module API

end
```
"""

# ╔═╡ 5c5423f2-27f7-4a4f-a895-18dcde6f518e
# hideall

begin
	bcontroller
	write(controllerPath, """module BooksController

using Genie
using Genie.Renderer.Html

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
	\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
  </ul>
  "
end

function billgatesbooks_view()
  html(:books, :billgatesbooks, books = BillGatesBooks)
end

function billgatesbooks_view_admin()
	html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
end

function billgatesbooks_view_md()
	html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
end


module API
using ..BooksController
using Genie.Renderer.Json

function billgatesbooks_view_json()
  json(BooksController.BillGatesBooks)
end

end # Module API

end""");
end;

# ╔═╡ 96a2b200-5f5c-49e5-8704-0cacf5acc93c
md"""
We nested an API module within the `BooksController` module, where we defined another `billgatesbooks` function which outputs a JSON.
"""

# ╔═╡ 69e57b2c-1bb1-4868-bbbc-af8c04bfa18d
md"""
If you go to `http://localhost:8000/api/v1/bgbooks_view_json` it should already work as expected.
"""

# ╔═╡ 089151b8-2fe3-4fc3-bc51-c45357e2895e
md"""
#### JSON views

However, we have just committed one of the cardinal sins of API development. We have just forever coupled our internal data structure to its external representation. This will make future refactoring very complicated and error prone as any changes in the data will break the client's integrations. The solution is to, again, use views, to fully control how we render our data – and decouple the data structure from its rendering on the web.

Genie has support for JSON views – these are plain Julia files which have the ".json.jl" extension. Let's add one in our `views/` folder:

"""

# ╔═╡ a040ddb3-8a73-423c-85db-9b4e5fdf387e
md"""

```julia
julia> touch(joinpath("app", "resources", "books", "views", "billgatesbooks.json.jl"))
"app/resources/books/views/billgatesbooks.json.jl"
```

"""

# ╔═╡ 6eb6f2d5-2d5c-44e3-98c1-c933844547e7
# hideall

begin
	jp = true;
	jsonPath = joinpath("$(dirname(pwd()))/MyGenieApp/", "app", "resources", "books", "views", "billgatesbooks.json.jl");
end;

# ╔═╡ 838f1cfb-5aed-4223-94b2-20fc339038af
md"""
We can now create a proper response. Put this in the view file:

```julia
# app/resources/books/views/billgatesbooks.json.jl
"Bill Gates' list of recommended books" => books
```
"""

# ╔═╡ 18cc67cf-93a2-417b-b385-680c68ddeb8e
# hideall

begin
	jp;
	write(jsonPath, """"Bill Gates' list of recommended books" => books""");
end;

# ╔═╡ a503b2b8-5405-43ca-921b-7e7a12a20f84
md"""
Final step, to instruct `BooksController` to render the view, add a `billgatesbooks_json_view` function within the `API` sub-module with the following:
"""

# ╔═╡ 43d19788-83cd-42fb-80d3-a38bfb7a7335
md"""
```julia
function billgatesbooks_view_json2()
  json(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
end
```
"""

# ╔═╡ e8b55050-3a62-4809-acc5-37cfb6afda4a
# hideall

begin
	jp
	bcontroller
	write(controllerPath, """module BooksController

	using Genie
	using Genie.Renderer.Html

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
		\$(["<li>\$(book.title) by \$(book.author)</li>" for book in BillGatesBooks]...)
	  </ul>
	  "
	end

	function billgatesbooks_view()
	  html(:books, :billgatesbooks, books = BillGatesBooks)
	end

	function billgatesbooks_view_admin()
		html(:books, :billgatesbooks, books = BillGatesBooks, layout = :admin)
	end

	function billgatesbooks_view_md()
		html(:books, "billgatesbooks.jl.md", books = BillGatesBooks)
	end


	module API
	using ..BooksController
	using Genie.Renderer.Json

	function billgatesbooks_view_json()
	  json(BooksController.BillGatesBooks)
	end

	function billgatesbooks_view_json2()
	  json(:books, :billgatesbooks, books = BooksController.BillGatesBooks)
	end

	end # Module API

	end""");
end;

# ╔═╡ 972325b6-5c17-4878-b4a2-a925742ad31e
md"""
Adding a route for the controller: 

```julia
# route.jl
route("/api/v2/bgbooks") do
  BooksController.API.billgatesbooks_view_json2()
end
```
"""

# ╔═╡ 9e29f394-a991-413f-be00-b4763accfd68
# hideall

begin
	jp;
	write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
	using Genie.Router
	using BooksController

	route("/bgbooks") do
	  BooksController.billgatesbooks()
	end

	route("/bgbooks_view") do
	  BooksController.billgatesbooks_view()
	end

	route("/bgbooks_view_admin") do
	  BooksController.billgatesbooks_view_admin()
	end

	route("/bgbooks_view_md") do
	  BooksController.billgatesbooks_view_md()
	end
	
	route("/api/v1/bgbooks_json") do
		BooksController.API.billgatesbooks_view_json()
	end
		
	route("/api/v2/bgbooks_json") do
		BooksController.API.billgatesbooks_view_json2()
	end""");
end;

# ╔═╡ d9d146f4-38bb-46f6-83f4-337374525f26
md"""
This should hold no surprises – the `json` function is similar to the `html` one we've seen before. So now we're rendering a custom JSON response. That's all – everything should work on `http://localhost:8000/api/v2/bgbooks`!
"""

# ╔═╡ 967e0015-d39d-4cf8-906e-7ac77fc28bb0
md"""
---
**HEADS UP**

#### Why JSON views have the extension ending in `.jl` but HTML and Markdown views do not?

Good question! The extension of the views is chosen in order to preserve correct syntax highlighting in the IDE/code editor.

Since practically HTML and Markdown views are HTML and Markdown files with some embedded Julia code, we want to use the HTML or Markdown syntax highlighting. For JSON views, we use pure Julia, so we want Julia syntax highlighting.

---
"""

# ╔═╡ 01f22a77-e334-4edc-a760-f8e2bf5452dc
md"""
## Accessing databases with `SearchLight` models

You can get the most out of Genie by pairing it with its seamless ORM layer, SearchLight. SearchLight, a native Julia ORM, provides excellent support for working with relational databases. The Genie + SearchLight combo can be used to productively develop CRUD (Create-Read-Update-Delete) apps.

---
**HEADS UP**

CRUD stands for Create-Read-Update-Delete and describes the data workflow in many web apps, where resources are created, read (listed), updated, and deleted.

---

SearchLight represents the "M" part in Genie's MVC architecture (thus, the Model layer).

Let's begin by adding SearchLight to our Genie app. All Genie apps manage their dependencies in their own Julia environment, through their `Project.toml` and `Manifest.toml` files.

So we need to make sure that we're in `pkg> ` shell mode first (which is entered by typing `]` in julian mode, ie: `julia>]`).
The cursor should change to `(MyGenieApp) pkg>`.
"""

# ╔═╡ 74cffd52-799d-445e-9535-e5c1849e3c59
md"""
Next, we add `SearchLight`:

```julia
(MyGenieApp) pkg> add SearchLight
```
"""

# ╔═╡ 1ae790c2-4006-497b-aafc-de701c097b50
md"""
### Adding a database adapter

`SearchLight` provides a database agnostic API for working with various backends (at the moment, MySQL, SQLite, and Postgres). Thus, we also need to add the specific adapter. To keep things simple, let's use SQLite for our app. Hence, we'll need the `SearchLightSQLite` package:

```julia
(MyGenieApp) pkg> add SearchLightSQLite
```
"""

# ╔═╡ 00396413-db51-4488-b500-ab35662e93e7
md"""
### Setup the database connection

Genie is designed to seamlessly integrate with SearchLight and provides access to various database oriented generators. First we need to tell Genie/SearchLight how to connect to the database. Let's use them to set up our database support. Run this in the Genie/Julia REPL:

```julia
julia> Genie.Generator.db_support()
```
"""

# ╔═╡ 478590e6-e01f-4fa3-8217-b03357a55cf3
# hideall

begin
	db = true;
	Genie.Generator.db_support(; dbadapter = :SQLite);
end;

# ╔═╡ 64ea16e4-4323-435f-9e13-9fe86ed31375
# hideall
begin
	db;
	using SearchLight;
end;

# ╔═╡ b208bfb8-e9ee-4f10-9dec-9248e30a7c9b
# hideall

begin
	db;
	using SearchLightSQLite;
end;

# ╔═╡ 415bec3c-4b56-480b-a779-105f1bfb3320
md"""
The command will add a `db/` folder within the root of the app. What we're looking for is the `db/connection.yml` file which tells SearchLight how to connect to the database. Let's edit it. Make the file look like this:

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:
```
"""

# ╔═╡ 173ef46e-a736-4f1f-9346-ed61a08541dd
md"""
This instructs SearchLight to run in the environment of the current Genie app (by default `dev`), using `SQLite` for the adapter (backend) and a database stored at `db/books.sqlite` (the database will be created automatically if it does not exist). We could pass extra configuration options in the `config` object, but for now we don't need anything else."""

# ╔═╡ ce069d56-3b12-4e6d-885b-83217e864b67
# hideall

begin
	db;
	db_path = "$(dirname(pwd()))/MyGenieApp/db/connection.yml";
end;

# ╔═╡ bc15b923-3d19-4daa-aa9a-f26ccc0f79c0
# hideall

begin
	db;
	chmod(db_path, 0o777);
end;

# ╔═╡ fcecf932-9084-49e9-9de8-a899bc0b5168
# hideall

begin
	db;
	write(db_path, """env: ENV["GENIE_ENV"]

dev:
  adapter: SQLite
  database: db/books.sqlite
  config:""");
end;	

# ╔═╡ 452a2397-923f-4349-90d4-813a87a254fb
md"""
---
**HEADS UP**

If you are using a different adapter, make sure that the database configured already exists and that the configured user can successfully access it -- SearchLight will not attempt to create the database.

---

Now we can ask SearchLight to load it up:

"""

# ╔═╡ f1153b95-aed8-4527-8e2a-fb1da2c79ad1
md"""

```julia
julia> using SearchLight

julia> SearchLight.Configuration.load()
Dict{String,Any} with 4 entries:
  "options"  => Dict{String,String}()
  "config"   => nothing
  "database" => "db/books.sqlite"
  "adapter"  => "SQLite"
```
"""

# ╔═╡ 65044e1c-039e-412c-b960-ebc3be23d1d9
# hideall

begin
	db;
	SearchLight.Configuration.load();
end;

# ╔═╡ 1c4625a3-c596-4651-9d22-ed104f854e13
md"""

Now we can ask SearchLight to load it up:

```julia
julia> using SearchLightSQLite

julia> SearchLight.Configuration.load() |> SearchLight.connect

```
"""

# ╔═╡ 5ff78c5b-3466-473e-8234-50a362cdc035
# hideall

begin
	db
	push!(SearchLightSQLite.CONNECTIONS, SearchLightSQLite.SQLite.DB(SearchLight.Configuration.load()["database"]))
end

# ╔═╡ 10e8ed24-aad8-4e56-96dc-a0e3511f3926
md"""
The connection succeeded and we got back a SQLite database handle.

"""

# ╔═╡ 7a09f6a9-6ab6-412d-82e8-e7fd065585d5
md"""
---
**PRO TIP**

Each database adapter exposes a `CONNECTIONS` collection where we can access the connection:
"""

# ╔═╡ 8e6c0262-247a-4d53-885c-f6756e03853b
md"""

```julia
julia> SearchLightSQLite.CONNECTIONS
1-element Array{SQLite.DB,1}:
 SQLite.DB("db/books.sqlite")
```
"""

# ╔═╡ d7460349-53b0-4c17-b9b8-23ac24f89c26
# hideall

SearchLightSQLite.CONNECTIONS

# ╔═╡ 54abd871-7b9c-4e85-90e7-dc25c2186441
md"""
Awesome! If all went well you should have a `books.sqlite` database in the `db/` folder (from the Julia REPL prompt, typing `;` will give the shell prompt).

```julia
shell> tree db
db
├── books.sqlite
├── connection.yml
├── migrations
└── seeds
```
"""

# ╔═╡ 2246f0b7-9257-451a-8987-598c6c8118c8
md"""
### Managing the database schema with `SearchLight` migrations

Database migrations provide a way to reliably, consistently and repeatedly apply (and undo) schema transformations. They are specialised scripts for adding, removing and altering DB tables – these scripts are placed under version control and are managed by a dedicated system which knows which scripts have been run and which not, and is able to run them in the correct order.

SearchLight needs its own DB table to keep track of the state of the migrations so let's set it up:
"""

# ╔═╡ f519f19b-9e5f-4933-ab6d-1d15f5001d09
md"""

```julia
julia> SearchLight.Migrations.create_migrations_table()
[ Info: Created table schema_migrations
```
"""

# ╔═╡ 5f45667e-6a8a-47c5-96a3-2e5d94b8b0c8
# hideall

begin
	db;
	SearchLight.Migrations.create_migrations_table();
end;

# ╔═╡ 85715e80-fc0d-4308-8de2-2ac1525192a3
md"""
This command sets up our database with the needed table in order to manage migrations.

---
**PRO TIP**

You can use the SearchLight API to execute random queries against the database backend. For example we can confirm that the table is really there:
"""

# ╔═╡ 6bc9e796-2794-4f24-8169-f5f04ea74f3e
md"""

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
"""

# ╔═╡ 421fe80d-6aee-44e7-b565-bab3d87fa7ad
# hideall

begin
	db;
	SearchLight.query("SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'");
end;

# ╔═╡ 56942d58-51db-4572-8de2-e2683d995b47
md"""
The result is a familiar `DataFrame` object.

---

### Creating our Book model

SearchLight, just like Genie, uses the convention-over-configuration design pattern. It prefers for things to be setup in a certain way and provides sensible defaults, versus having to define everything in extensive configuration files. And fortunately, we don't even have to remember what these conventions are, as SearchLight also comes with an extensive set of generators.

Lets ask SearchLight to create a new model:
"""

# ╔═╡ 62dd9bf0-cf14-444f-96bb-00c6b6197f02
md"""

```julia
julia> SearchLight.Generator.newresource("Book")

[ Info: New model created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/Books.jl
[ Info: New table migration created at /Users/adrian/Dropbox/Projects/MyGenieApp/db/migrations/2020020909574048_create_table_books.jl
[ Info: New validator created at /Users/adrian/Dropbox/Projects/MyGenieApp/app/resources/books/BooksValidator.jl
[ Info: New unit test created at /Users/adrian/Dropbox/Projects/MyGenieApp/test/books_test.jl

```
"""

# ╔═╡ 546ed22e-367c-4304-936b-e64c13a9593e
# hideall

begin
	db;
	b_resource = true;
	SearchLight.Generator.newresource("Book");
end;

# ╔═╡ 3979e04b-2009-4b57-a8de-9a41de6ad2ed
md"""
SearchLight has created the `Books.jl` model, the `*_create_table_books.jl` migration file, the `BooksValidator.jl` model validator and the `books_test.jl` test file.
"""

# ╔═╡ 0e1df9fa-f608-4d15-89f0-3c9c87c62625
md"""
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
"""

# ╔═╡ 7d0cbfcd-786c-49c9-a211-e941a87562fb
# hideall

begin
	b_resource;
	migrations = readdir("$(dirname(pwd()))/MyGenieApp/db/migrations");
end;

# ╔═╡ 085320e0-7eff-4f51-8e35-54d4a793f80c
# hideall

begin
	b_resource;
	migration_file = migrations[2];
end;

# ╔═╡ 1161c5da-1bbe-4f20-be3f-436ca712a792
# hideall 

begin
	b_resource;
	migration_full_path = "$(dirname(pwd()))/MyGenieApp/db/migrations/$(migration_file)";
end;

# ╔═╡ 4e7e11ed-5f00-4560-aecd-a415421ef409
# hideall

begin
	b_resource;
	write(migration_full_path, """module CreateTableBooks

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

end""");
end;

# ╔═╡ 451afdfc-4393-4dac-9eab-e05e1111149a
md"""
The DSL is pretty readable: in the `up` function we call `create_table` and pass an array of columns: a primary key, a `title` column and an `author` column (both strings have a max length of 100). We also add two indices (one on the `title` and the other on the `author` columns). As for the `down` method, it invokes the `drop_table` function to remove the table.

#### Running the migration

We can see what SearchLight knows about our migrations with the `SearchLight.Migrations.status()` command:
"""

# ╔═╡ c895263f-a731-4293-9ae5-c916ecb5eb73
md"""

```julia

julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                 CreateTableBooks: DOWN |
| 1 | 2020020909574048_create_table_books.jl |
```
"""

# ╔═╡ 70757a88-96b5-4cb5-9430-6966cdc93878
# hideall

begin
	b_resource;
	SearchLight.Migrations.status();
end;

# ╔═╡ 2762decf-bbe0-4575-91f5-8d59a1d1d722
md"""
So our migration is in the `down` state – meaning that its `up` method has not been run. We can easily fix this:
"""

# ╔═╡ c0d9c5a8-4c98-4d3d-8c2c-60ffb2910d82
md"""

```julia
julia> SearchLight.Migrations.last_up()
[ Info: Executed migration CreateTableBooks up
```
"""

# ╔═╡ e817c5c1-0d06-4602-b559-30b177a4c6f3
md"""

If we recheck the status, the migration is up:

```julia
julia> SearchLight.Migrations.status()
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                   CreateTableBooks: UP |
| 1 | 2020020909574048_create_table_books.jl |
```
"""

# ╔═╡ 05bb7631-fbe0-4cf8-9408-dc8afcc3853c
# hideall

begin
	b_resource;
	SearchLight.Migration.last_up();
end;

# ╔═╡ 22914aec-cc4c-43e0-a670-0e0e34af0766
# hideall

begin
	b_resource;
	SearchLight.Migration.status();
end;

# ╔═╡ 66257911-9bb3-46fc-94b7-2919864679f0
md"""
Our table is ready!

"""

# ╔═╡ af8ac53b-4386-451e-ba37-7d1cbc8217e8
md"""
#### Defining the model

Now it's time to edit our model file at `app/resources/books/Books.jl`. Another convention in SearchLight is that we're using the pluralized name (`Books`) for the module – because it's for managing multiple books. And within it we define a type (a `mutable struct`), called `Book` – which represents an item (a single book) which maps to a row in the underlying database.

Edit the `Books.jl` file to make it look like this:


```julia
# Books.jl
module Books

import SearchLight: AbstractModel, DbId, save!

import Base: @kwdef

export Book

@kwdef mutable struct Book <: AbstractModel
  id::DbId = DbId()
  title::String = ""
  author::String = ""
end

end
```

"""

# ╔═╡ a3a62e23-5ec5-4d3d-93dc-cb45c4a93a00
# hideall

begin
	bmodel = true;
	modelPath = "$(dirname(pwd()))/MyGenieApp/app/resources/books/Books.jl";
end;

# ╔═╡ 22b3e23a-e0b6-4d93-92ba-bd1da11dadfc
# hideall

begin
	bmodel;
	write(modelPath, """# Books.jl
module Books

import SearchLight: AbstractModel, DbId, save!

# @kwdef is not exported by Base and, theoretically, should not be used since it is an internal symbol.
# If you want, you could instead use the @with_kw macro from the Parameters.jl package.
import Base: @kwdef

export Book

@kwdef mutable struct Book <: AbstractModel
  id::DbId = DbId()
  title::String = ""
  author::String = ""
end

end""");
end;

# ╔═╡ 299f48f2-ed9b-4de3-a24a-8bb69ef75ded
md"""
We defined a `mutable struct` which matches our previous `Book` type by using the `@kwdef` macro, in order to also define a keyword constructor, as SearchLight needs it.

#### Using our model

To make things more interesting, we should import our current books into the database. Add this function to the `Books.jl` module, following the `Book()` constructor definition (just above the module's closing `end`):

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
    Book(title = b[1], author = b[2]) |> save!
  end
end
```
"""

# ╔═╡ b7482bb2-24eb-471a-9229-0bbbb9b3e6a9
# hideall

begin
	bmodel;
	write(modelPath, """# Books.jl
module Books

import SearchLight: AbstractModel, DbId, save!

# @kwdef is not exported by Base and, theoretically, should not be used since it is an internal symbol.
# If you want, you could instead use the @with_kw macro from the Parameters.jl package.
import Base: @kwdef

export Book

@kwdef mutable struct Book <: AbstractModel
  id::DbId = DbId()
  title::String = ""
  author::String = ""
end
		
function seed()
  BillGatesBooks = [
    ("The Best We Could Do", "Thi Bui"),
    ("Evicted: Poverty and Profit in the American City", "Matthew Desmond"),
    ("Believe Me: A Memoir of Love, Death, and Jazz Chickens", "Eddie Izzard"),
    ("The Sympathizer!", "Viet Thanh Nguyen"),
    ("Energy and Civilization, A History", "Vaclav Smil")
  ]

  for b in BillGatesBooks
    Book(title = b[1], author = b[2]) |> save!
  end
end

end""");
end;

# ╔═╡ b62b0020-0182-4767-a7f9-4ab6e4cfdfe7
md"""
#### Auto-loading the DB configuration

Now, to try things out. Genie takes care of loading all our resource files for us when we load the app. To do this, Genie comes with a special file called an initializer, which automatically loads the database configuration and sets up SearchLight. Check `config/initializers/searchlight.jl`. It should look like this:

```julia
using SearchLight

try
  SearchLight.Configuration.load()

  if SearchLight.config.db_config_settings["adapter"] !== nothing
    eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
    SearchLight.connect()
  end
catch ex
  @error ex
end
```
"""

# ╔═╡ 90242b23-e853-4b4b-a08c-2af95ade39a6
md"""
---
**Heads up!**

All the `*.jl` files placed into the `config/initializers/` folder are automatically included by Genie upon starting the Genie app. They are included early (upon initialisation), before the controllers, models, views, are loaded.

---

#### Trying it out

Now it's time to restart our REPL session and test our app. Close the Julia REPL session to exit to the OS command line and run:

```bash
$ bin/repl
```

In Windows go into the `bin/` folder within the application's directory and run `repl.bat` in the terminal.

The `repl` executable script placed within the app's `bin/` folder starts a new Julia REPL session and loads the applications' environment. Everything should be automatically loaded now, DB configuration included - so we can invoke the previously defined `seed` function to insert the books:

"""

# ╔═╡ 8c49a163-0602-476d-8a97-d5055d25e88c
md"""
```julia
julia> using Books

julia> Books.seed()
```

"""

# ╔═╡ dab899f2-b237-4edc-9263-171770373c9c
# hideall

begin
	book_model = true;
	book_path = joinpath("$(dirname(pwd()))/MyGenieApp/app/resources", "books", "Books.jl");
end;

# ╔═╡ e84ac231-c915-4a8d-bf77-566400e29721
# hideall

begin
	book_model;
	books = include(book_path);
end;

# ╔═╡ 231dbc05-6c9c-45de-8f1d-92ede14f0e0e
# hideall

Main.var"workspace#2".Books;

# ╔═╡ 737fe343-e840-4bff-9a02-b124137cc50f
# hideall

begin
	book_model;
	books.Books.seed();
end;

# ╔═╡ 59389cc2-f185-46c1-8765-f0c40ddae332
md"""


```julia
julia> Books.seed()
[ Info: INSERT  INTO books ("title", "author") VALUES ('The Best We Could Do', 'Thi Bui')
[ Info: INSERT  INTO books ("title", "author") VALUES ('Evicted: Poverty and Profit in the American City', 'Matthew Desmond')

# output truncated
```
"""

# ╔═╡ 06b5f6f1-b4f1-4808-a623-eb94ccdd1020
md"""
If you want to make sure all went right (although trust me, it did, otherwise SearchLight would've thrown an `Exception`!), just ask SearchLight to retrieve them:
"""

# ╔═╡ a4b1c687-9f97-4bd4-b236-1d7aafbed55b
md"""
```julia
julia> using SearchLight

julia> all(Book)

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
"""

# ╔═╡ 332dc5d3-b259-4bc5-ae06-3a3f1808f566
# hideall

SearchLight.all(books.Book);

# ╔═╡ 1bd58d79-d41e-4347-8f55-10b432d40a03
md"""
The `SearchLight.all` method returns all the `Book` items from the database.

All good!

The next thing we need to do is to update our controller to use the model. Make sure that `app/resources/books/BooksController.jl` reads like this:
"""

# ╔═╡ 85089bed-c8fe-43b6-b47e-7966a94febfa
md"""

```julia
# BooksController.jl
module BooksController

using Genie.Renderer.Html, SearchLight, Books

function billgatesbooks_sqlite()
  html(:books, :billgatesbooks, books = all(Book))
end

module API

using ..BooksController
using Genie.Renderer.Json, SearchLight, Books

function billgatesbooks_view_sqlite()
  json(:books, :billgatesbooks_sqlite, books = all(Book))
end

end

end
```
"""

# ╔═╡ 23e44d6d-adbe-4fc8-a6a3-6259feb3db56
# hideall

begin
	bcontroller
	write(controllerPath, """module BooksController

using Genie.Renderer.Html, SearchLight, Books

function billgatesbooks_sqlite()
  html(:books, :billgatesbooks, books = all(Book))
end

module API

using ..BooksController
using Genie.Renderer.Json, SearchLight, Books

function billgatesbooks_view_sqlite()
  json(:books, :billgatesbooks_sqlite, books = all(Book))
end

end

end""");
end;

# ╔═╡ efbcef3d-c679-48af-b7d2-b81e756c8c00
md"""
Our JSON view needs tweaking too. let's create a new view file `billgatesbooks_sqlite.json.jl` with the following content:

```julia
# app/resources/books/views/billgatesbooks_sqlite.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in books]
```
"""

# ╔═╡ 2f29380e-4480-439c-9d9a-0d0660eec76e
# hideall

begin
	jsonView = true;
	jvPath = "$(dirname(pwd()))/MyGenieApp/app/resources/books/views/billgatesbooks_sqlite.json.jl"
end;

# ╔═╡ ac8700bf-5636-4e1c-8efe-81fe1e8cca9d
# hideall

begin
	jsonView;
	touch(jvPath);
end;

# ╔═╡ 5c02709d-3ab2-4a3f-99bc-5885032b5b6c
# hideall

begin
	jsonView;
	write(jvPath, """# app/resources/books/views/billgatesbooks_sqlite.json.jl
"Bill's Gates list of recommended books" => [Dict("author" => b.author, "title" => b.title) for b in books]""");
end;

# ╔═╡ 2bfab687-d885-4a16-a04b-4c7b419e35fb
md"""

---
**Heads up!**

In the sub-module `API`, the parameter `:billgatesbooks_sqlite` reflects the new file named `billgatesbooks_sqlite.json.jl`!

---

Let's also add a new route:

```julia
# route.jl
route("/api/v3/bgbooks_json") do
  BooksController.API.billgatesbooks_view_sqlite()
end
```
"""

# ╔═╡ be526029-3efd-49d8-a84e-97e57cb0a7d9
# hideall

write("$(dirname(pwd()))/MyGenieApp/routes.jl", """# routes.jl
using Genie.Router
using BooksController

route("/bgbooks") do
  BooksController.billgatesbooks()
end

route("/bgbooks_view") do
  BooksController.billgatesbooks_view()
end

route("/bgbooks_view_admin") do
  BooksController.billgatesbooks_view_admin()
end

route("/bgbooks_view_md") do
  BooksController.billgatesbooks_view_md()
end

route("/api/v1/bgbooks_json") do
	BooksController.API.billgatesbooks_view_json()
end
	
route("/api/v2/bgbooks_json") do
	BooksController.API.billgatesbooks_view_json2()
end

route("/api/v3/bgbooks_json") do
  BooksController.API.billgatesbooks_view_sqlite()
end""");

# ╔═╡ 5e0e44f1-c147-435b-84a3-5276df050971
md"""
The `up` method starts up the web server and takes us back to the interactive Julia REPL prompt.

Now, if, for example, we navigate to <http://localhost:8000/api/v3/bgbooks_json>, the output should match the following JSON document (edited with newlines for clarity):

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
"""

# ╔═╡ fe03b826-66a0-46a1-98eb-58ee7c1f2718
md"""

Let's add a new book to see how it works. We'll create a new Book item and persist it using the `SearchLight.save!` method:

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
"""

# ╔═╡ ffb91f85-66f5-4dc8-bfdd-2605f013848a
md"""

Calling the `save!` method, SearchLight has persisted the object in the database and then retrieved it and returned it (notice the updated `id::DbId` field).

The same `save!` operation can be written as a one-liner:


"""

# ╔═╡ 0c0862c3-7faa-46db-9374-59a6ebe0d136
md"""

```julia
julia> Book(title = "Leonardo da Vinci", author = "Walter Isaacson") |> save!
```
"""

# ╔═╡ 9e5e0aa9-c3d1-446b-9d41-088d41ff40c5
md"""

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

"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
Revise = "295af30f-e4ad-537b-8983-00126c2a3abe"
SearchLight = "340e8cb6-72eb-11e8-37ce-c97ebeb32050"
SearchLightSQLite = "21a827c4-482a-11ea-3a19-4d2243a4a2c5"

[compat]
Genie = "~4.9.1"
Revise = "~3.3.1"
SearchLight = "~2.1.0"
SearchLightSQLite = "~2.0.0"
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

[[BinaryProvider]]
deps = ["Libdl", "Logging", "SHA"]
git-tree-sha1 = "ecdec412a9abc8db54c0efc5548c64dfce072058"
uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
version = "0.5.10"

[[CSTParser]]
deps = ["Tokenize"]
git-tree-sha1 = "f9a6389348207faf5e5c62cbc7e89d19688d338a"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.3.0"

[[CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

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

[[Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[DBInterface]]
git-tree-sha1 = "9b0dc525a052b9269ccc5f7f04d5b3639c65bca5"
uuid = "a10d1c49-ce27-4219-8d33-6db1a4562965"
version = "2.5.0"

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
deps = ["Libdl"]
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
deps = ["Serialization"]
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

[[SQLite]]
deps = ["BinaryProvider", "DBInterface", "Dates", "Libdl", "Random", "SQLite_jll", "Serialization", "Tables", "Test", "WeakRefStrings"]
git-tree-sha1 = "8e14d9b200b975e93a0ae0e5d17dea1c262690ee"
uuid = "0aa819cd-b072-5ff4-a722-6bc24af294d9"
version = "1.4.0"

[[SQLite_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cca82caa0b6bf7f0bc977e69063c0cf5d7da36e5"
uuid = "76ed43ae-9a5d-5a62-8c75-30186b810ce8"
version = "3.37.0+0"

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

[[SearchLightSQLite]]
deps = ["DBInterface", "DataFrames", "Logging", "SQLite", "SearchLight"]
git-tree-sha1 = "f56a4eb6cbbe3d84746aa2a5b509a47e0003d699"
uuid = "21a827c4-482a-11ea-3a19-4d2243a4a2c5"
version = "2.0.0"

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

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─de3d681a-424a-11ec-0a26-574b0c85d733
# ╟─dfce7e49-2848-4656-8880-386cfcd99ffe
# ╠═1104aef8-6de4-4fb0-b0d1-6e85df6e86e0
# ╠═c2e80b10-502e-46c8-b802-ee9956b63fcc
# ╟─628696ba-4d35-4be9-9ffd-e1e1fd583449
# ╟─2ee6a844-c14b-4ee1-a444-e883ade1e0ec
# ╟─a7e80773-02e0-4352-b04e-c84b6a995ffe
# ╟─ea12f1c9-b48e-4575-be03-d9ecc65062e9
# ╠═a0d85997-d167-4c8b-a2f2-e50ef4c2193e
# ╠═d7cb397d-3042-4858-baf3-833f3c70083f
# ╟─11659bac-808b-48be-be7c-fff4b2f262c5
# ╟─9363139c-17b1-446b-b7bd-c72bf18bf8f2
# ╠═b2667ebb-10d4-4233-804d-589f3d108dc6
# ╟─2141f87a-9beb-43d9-8129-5b17dc3400ab
# ╠═29c0bdfa-a7dc-44c6-9e97-03ab9883828b
# ╟─e879fd0d-4399-4ef9-8fdf-75cc7d00bb29
# ╠═f63d7226-ffcc-4402-bb2d-37cfe2d64593
# ╠═09764303-330e-4c47-92ed-cb6ce13d629d
# ╟─fdaceba9-6d8e-4b5a-b654-7a73c7dc92d6
# ╟─6ba091fe-876c-45d5-8e1c-5963ae95686f
# ╟─e96e7baf-a1fa-4662-b3f4-885b4810592d
# ╟─19e78a3c-1f67-40fb-9863-c3155bed1136
# ╠═adece903-915b-4f77-997d-e5fe5e49ebd7
# ╟─06ec4ef2-b262-42f7-baa4-c2b7e1dbe4f8
# ╠═50299fe8-6a8c-4121-8e20-7b0b83f66a65
# ╟─5eca6084-5f1e-4727-831e-fa0e6547c214
# ╟─88985c2d-48e8-4b6b-925d-7cfa05518b9a
# ╟─0cc74c5f-f700-416d-aa70-fd76682ad16f
# ╟─93fd2d47-685a-4955-b594-5e0693913c98
# ╠═a4c1b657-14d4-4035-aa7c-4ba78a6c9f34
# ╟─52b7147b-a1b0-4ebf-a25c-a4fbde3f8090
# ╟─3d305148-5bdc-41cf-814d-19b6e7319ff9
# ╟─bad5f961-cd90-4a63-ba5a-b873605f16b5
# ╠═82c6343d-59d7-4e5b-ac0f-a12c2ac133e1
# ╠═7777a8b8-4e62-43bf-920f-9e0a422e51b8
# ╟─0ec7409a-6bbc-4fdf-94b4-43f9aebe0bfb
# ╠═3dacfdaa-8016-4bab-bf31-882e2cd88b8b
# ╟─ce610c99-79a0-4e08-97a8-2f9ed2766598
# ╠═b6eb4bbb-2fad-465c-897e-6442ac485c61
# ╟─ba672e36-f0f3-472d-af0c-517c4d61d689
# ╠═6ae6af95-6f00-480d-bf78-de1d8bf2a38b
# ╟─32313d61-8200-4597-aa50-7bf1ced975eb
# ╟─13addf69-7308-4652-9ada-d97040da9f03
# ╟─76509397-be50-4b27-b72f-548964856402
# ╠═f9787fca-1aad-46f4-9676-5e17b0ad7f09
# ╠═d29af1bd-4da0-459b-ab65-da31933ee77c
# ╟─fa9c6f04-81c8-417a-a140-adb0dea442b1
# ╠═7dd69c90-1d40-4bef-aa69-30acd53209d2
# ╟─74b18c8c-7751-4d53-a83d-efeb7c03cb8f
# ╠═6f363e5c-dcec-4f5e-bcac-409356b873de
# ╠═24462235-7bc4-4de0-b377-ab038e4b3da3
# ╟─bcf0085c-86b3-4c38-96e2-315346df552c
# ╟─204c774c-d1e7-4e01-bd7a-ae67ed151584
# ╠═3e61a74b-e96b-4238-a898-07c0e71c920c
# ╠═b3b1eb3d-f098-4934-ba23-10cd9ce8887f
# ╠═3972b319-95ae-48cd-9910-a8e17b9afbdf
# ╟─1b96a87b-2a2e-4a2a-9410-ef6181db13a2
# ╠═87c9d856-18bd-4f66-9c07-d0ac8dd88b7c
# ╟─86c06852-d381-497a-9348-78b87368867a
# ╟─d70da414-0002-466e-89d3-a60a94d5dae2
# ╠═b6f5e3f2-34a7-4ffa-9636-88b4bb03e555
# ╠═9cec384c-6ae3-4dd4-b2c8-8ad8e919e92f
# ╟─f9f12618-d00a-4a5a-9569-3540d7ba7515
# ╟─28d65796-dfd5-4dba-b8dd-4d4c08e75e18
# ╟─40daa02f-2fd8-4f29-88ec-b229fe59025b
# ╠═5ced7f6e-e84a-4cbf-9990-6cb3830362d5
# ╟─834850bb-fc3e-44b6-8dd8-32adb93ddcae
# ╠═5c5423f2-27f7-4a4f-a895-18dcde6f518e
# ╟─96a2b200-5f5c-49e5-8704-0cacf5acc93c
# ╟─69e57b2c-1bb1-4868-bbbc-af8c04bfa18d
# ╟─089151b8-2fe3-4fc3-bc51-c45357e2895e
# ╟─a040ddb3-8a73-423c-85db-9b4e5fdf387e
# ╠═6eb6f2d5-2d5c-44e3-98c1-c933844547e7
# ╟─838f1cfb-5aed-4223-94b2-20fc339038af
# ╠═18cc67cf-93a2-417b-b385-680c68ddeb8e
# ╟─a503b2b8-5405-43ca-921b-7e7a12a20f84
# ╟─43d19788-83cd-42fb-80d3-a38bfb7a7335
# ╠═e8b55050-3a62-4809-acc5-37cfb6afda4a
# ╟─972325b6-5c17-4878-b4a2-a925742ad31e
# ╠═9e29f394-a991-413f-be00-b4763accfd68
# ╟─d9d146f4-38bb-46f6-83f4-337374525f26
# ╟─967e0015-d39d-4cf8-906e-7ac77fc28bb0
# ╟─01f22a77-e334-4edc-a760-f8e2bf5452dc
# ╟─74cffd52-799d-445e-9535-e5c1849e3c59
# ╠═64ea16e4-4323-435f-9e13-9fe86ed31375
# ╟─1ae790c2-4006-497b-aafc-de701c097b50
# ╠═b208bfb8-e9ee-4f10-9dec-9248e30a7c9b
# ╟─00396413-db51-4488-b500-ab35662e93e7
# ╠═478590e6-e01f-4fa3-8217-b03357a55cf3
# ╟─415bec3c-4b56-480b-a779-105f1bfb3320
# ╟─173ef46e-a736-4f1f-9346-ed61a08541dd
# ╠═ce069d56-3b12-4e6d-885b-83217e864b67
# ╠═bc15b923-3d19-4daa-aa9a-f26ccc0f79c0
# ╠═fcecf932-9084-49e9-9de8-a899bc0b5168
# ╟─452a2397-923f-4349-90d4-813a87a254fb
# ╟─f1153b95-aed8-4527-8e2a-fb1da2c79ad1
# ╠═65044e1c-039e-412c-b960-ebc3be23d1d9
# ╟─1c4625a3-c596-4651-9d22-ed104f854e13
# ╠═5ff78c5b-3466-473e-8234-50a362cdc035
# ╟─10e8ed24-aad8-4e56-96dc-a0e3511f3926
# ╟─7a09f6a9-6ab6-412d-82e8-e7fd065585d5
# ╟─8e6c0262-247a-4d53-885c-f6756e03853b
# ╠═d7460349-53b0-4c17-b9b8-23ac24f89c26
# ╟─54abd871-7b9c-4e85-90e7-dc25c2186441
# ╟─2246f0b7-9257-451a-8987-598c6c8118c8
# ╟─f519f19b-9e5f-4933-ab6d-1d15f5001d09
# ╠═5f45667e-6a8a-47c5-96a3-2e5d94b8b0c8
# ╟─85715e80-fc0d-4308-8de2-2ac1525192a3
# ╟─6bc9e796-2794-4f24-8169-f5f04ea74f3e
# ╠═421fe80d-6aee-44e7-b565-bab3d87fa7ad
# ╟─56942d58-51db-4572-8de2-e2683d995b47
# ╟─62dd9bf0-cf14-444f-96bb-00c6b6197f02
# ╠═546ed22e-367c-4304-936b-e64c13a9593e
# ╟─3979e04b-2009-4b57-a8de-9a41de6ad2ed
# ╟─0e1df9fa-f608-4d15-89f0-3c9c87c62625
# ╠═7d0cbfcd-786c-49c9-a211-e941a87562fb
# ╠═085320e0-7eff-4f51-8e35-54d4a793f80c
# ╠═1161c5da-1bbe-4f20-be3f-436ca712a792
# ╠═4e7e11ed-5f00-4560-aecd-a415421ef409
# ╟─451afdfc-4393-4dac-9eab-e05e1111149a
# ╟─c895263f-a731-4293-9ae5-c916ecb5eb73
# ╠═70757a88-96b5-4cb5-9430-6966cdc93878
# ╟─2762decf-bbe0-4575-91f5-8d59a1d1d722
# ╟─c0d9c5a8-4c98-4d3d-8c2c-60ffb2910d82
# ╟─e817c5c1-0d06-4602-b559-30b177a4c6f3
# ╠═05bb7631-fbe0-4cf8-9408-dc8afcc3853c
# ╠═22914aec-cc4c-43e0-a670-0e0e34af0766
# ╟─66257911-9bb3-46fc-94b7-2919864679f0
# ╟─af8ac53b-4386-451e-ba37-7d1cbc8217e8
# ╠═a3a62e23-5ec5-4d3d-93dc-cb45c4a93a00
# ╠═22b3e23a-e0b6-4d93-92ba-bd1da11dadfc
# ╟─299f48f2-ed9b-4de3-a24a-8bb69ef75ded
# ╠═b7482bb2-24eb-471a-9229-0bbbb9b3e6a9
# ╟─b62b0020-0182-4767-a7f9-4ab6e4cfdfe7
# ╟─90242b23-e853-4b4b-a08c-2af95ade39a6
# ╟─8c49a163-0602-476d-8a97-d5055d25e88c
# ╠═dab899f2-b237-4edc-9263-171770373c9c
# ╠═e84ac231-c915-4a8d-bf77-566400e29721
# ╠═231dbc05-6c9c-45de-8f1d-92ede14f0e0e
# ╠═737fe343-e840-4bff-9a02-b124137cc50f
# ╟─59389cc2-f185-46c1-8765-f0c40ddae332
# ╟─06b5f6f1-b4f1-4808-a623-eb94ccdd1020
# ╟─a4b1c687-9f97-4bd4-b236-1d7aafbed55b
# ╠═332dc5d3-b259-4bc5-ae06-3a3f1808f566
# ╟─1bd58d79-d41e-4347-8f55-10b432d40a03
# ╟─85089bed-c8fe-43b6-b47e-7966a94febfa
# ╠═23e44d6d-adbe-4fc8-a6a3-6259feb3db56
# ╟─efbcef3d-c679-48af-b7d2-b81e756c8c00
# ╠═2f29380e-4480-439c-9d9a-0d0660eec76e
# ╠═ac8700bf-5636-4e1c-8efe-81fe1e8cca9d
# ╠═5c02709d-3ab2-4a3f-99bc-5885032b5b6c
# ╟─2bfab687-d885-4a16-a04b-4c7b419e35fb
# ╠═be526029-3efd-49d8-a84e-97e57cb0a7d9
# ╟─5e0e44f1-c147-435b-84a3-5276df050971
# ╟─fe03b826-66a0-46a1-98eb-58ee7c1f2718
# ╟─ffb91f85-66f5-4dc8-bfdd-2605f013848a
# ╟─0c0862c3-7faa-46db-9374-59a6ebe0d136
# ╟─9e5e0aa9-c3d1-446b-9d41-088d41ff40c5
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
