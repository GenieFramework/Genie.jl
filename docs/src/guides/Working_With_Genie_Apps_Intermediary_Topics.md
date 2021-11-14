# Working With Genie Apps: Intermediate Topics

---
**HEADS UP**

This guide is still work in progress and some things might not work as expected. We're
working on it though and it should be ready in a couple of weeks. You can star and follow
Genie on Github to be notified when updates are added.

---

## Introduction

In this guide, we will improve on the _Working with Genie Apps_ guide with a form to add new
books. We will:

- introduce how a worflow connecting different parts of a webapp; and
- use symbols to abstract that workflow that can ease later refactoring.

Let us restart the project created in the _Working with Genie Apps_ guide. Run the
following:

```shell
bin/repl
```

Then launch the server:

```julia
up(8000, "127.0.0.1")
```

---

*** HEAD-UP ***

You can stop the server with `down()`. Alternatively, you could run
`up(8000, "127.0.0.1", async = false)` and stop the server with Ctrl/Cmd+C.

---


## Handling forms

Now, the problem is that Bill Gates reads – a lot! It would be much easier if we would allow
our users to add a few books themselves, to give us a hand. But since, obviously, we're not
going to give them access to our Julia REPL, we should setup a web page with a form. Let's
do it.

Conceptually, we need a form to input the information about a new book. Then we need a way
to add that information to the database. The parts of that workflow are associated to two
symbols. We will associate the new form with the symbol `:intermediate_new`. The choice of
the symbol name is yours entirelly. Here the suffix `intermediate_` just indicates that we
are in the _intermediate_ guide. We will associate the creation of the database entry to the
symbol `:intermediate_create`. The reason for using symbols will become clear as you
progress.


### Routes

Routes are the first important step as the link the step of the workflow (represented by the
symbol), where to find on the webpage (its actual route) and the controller.

We'll start by adding the new routes (again, note that the names are intentionally different
from the routes used in the "Working With Genie Apps" guide):

```julia
# routes.jl
route(
  "/bgbook_db_intermediate/new",
  BookDBsController.intermediate_new;
  method = GET,
  named = :intermediate_new)

route(
  "/bgbook_db_intermediate/create",
  BookDBsController.intermediate_create;
  method = POST,
  named = :intermediate_create)
```

We intentionally use very different name to make it clear that they are completely
unrelated. The more confusing
`route("/new_book", BookDBsController.new_book; method = GET, named = :new_book)` would work
too, but would suggest that they are all somehow linked. It also makes it clear that a quick
change of those definition fields allow for quick refactoring exploration.

Those definitions are in fact more important than simply defining a webpage route. They
connect the route itself, a controller associated with that route and a symbol that allows
other parts of the app to refenrece to this route. In a sense, the most important parameter
is the symbol: the route and its controller could be refactored but the logic of the app
would remain OK.

Note also the `DB` everywhere to make it clear that we are using the database version of the
app.


### Controller

Now, let's add the two methods `intermediate_new()` and `intermediate_create()` in
`BookDBsController`. Add these definition in the `BookDBsController` module (make sure you
add them in `BookDBsController`, not in `BookDBsController.API`):

```julia
# BookDBsController.jl
function intermediate_new()
  html(:bookdbs, :intermediate_form_new)
end

function intermediate_create()
  # code here
end
```

The `intermediate_new()` method should be read as:

- `:bookdbs`: it relates to the `bookdbs` resource;
- `html()`: it will look for a view defined as a HTML file;
- `:intermediate_form_new`: the HTML file should be named `intermediate_form_new.jl.html`.

`intermediate_create()` is just a placeholder for now.



### View

Next, to add our view. Add a blank file called `intermediate_form_new.jl.html` in
`app/resources/bookdbs/views`. Using Julia:

```julia
julia> touch("app/resources/bookdbs/views/intermediate_form_new.jl.html")
```

Make sure that it has this content:

```html
<!-- app/resources/bookdbs/views/intermediate_form_new.jl.html -->
<h2>Add a new book recommended by Bill Gates</h2>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books" target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.linkto(:create_intermediate))" method="POST">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="submit" value="Add book" />
</form>
```


Notice that the form's action calls the `linkto` method. That link describes the workflow:
after information about a new book is collected, then we need to create it. The link refers
to the symbol `:intermediate_create` that we used in `routes.jl`. `routes.jl` associates
`:intermediate_create` to the route `/bgbooks_db_intermediate/create`. Therefore, the
`linksto` method results in the generation of the following HTML:
`<form method="POST" action="/bgbooks_intermediate/create">`.

`routes.jl` also associates `:intermediate_create` to the
`BooksController.intermediate_create` function to actually create a new book, persist it to
the database and then redirect to refresh the display with the new full list of books. Here
is the code:

```julia
# BooksController.jl
function intermediate_create()
  BookDB(title = params(:book_title), author = params(:book_author)) |> save &&
    redirect(:bgbooks_db_view_json)
end
```

A few things are worth pointing out in this snippet:

- we're accessing the `params` collection to extract the request data, in this case passing
  in the names of our form's inputs as parameters. We need to bring `Genie.Router` into
  scope in order to access `params`;

- we're using the `redirect` method to perform a HTTP redirect. As the argument we're
  passing in the name of the route, just like we did with the form's action. In this guide,
  we explicitly provided names (`:intermediate_new` and `:intermediate_create`). Recall that
  we did not do that in the previous _Working with Genie Apps_ guide. However, it turns out
  that Genie gives default names to all the unnamed routes.

- A word of caution: **these names are generated using the properties of the route, so if
  the route changes it's possible that the name will change too**. So either make sure the
  properties of your route stays unchanged – or explicitly name your routes with `named = [SYMBOL]`.

- Here, the name used is `bgbooks_db_view_json` which was used in the previous guide. If
  nothing had been given, a name would have been autogenerated as `:get_api_v3_bgbookdbs` to
  reflect the method (`GET`) and the route (`/api/v3/bgbookdbs`).

In order to get info about the defined routes you can use the `Router.named_routes`
function:

```julia
julia> Router.named_routes()

OrderedCollections.OrderedDict{Symbol, Genie.Router.Route} with 14 entries:
  :get                         => [GET] / => #7 | :get
  :get_hello                   => [GET] /hello => #9 | :get_hello
  :get_bgbooks                 => [GET] /bgbooks => #11 | :get_bgbooks
  :get_bgbooks_gen             => [GET] /bgbooks_gen => #13 | :get_bgbooks_gen
  :get_bgbooks_view_html       => [GET] /bgbooks_view_html => #15 | :get_bgbooks_view_html
  :get_bgbooks_view_html_admin => [GET] /bgbooks_view_html_admin => #17 | :get_bgbooks_view_html_admin
  :get_bgbooks_view_md         => [GET] /bgbooks_view_md => #19 | :get_bgbooks_view_md
  :get_api_v1_bgbooks          => [GET] /api/v1/bgbooks => #21 | :get_api_v1_bgbooks
  :get_api_v2_bgbooks          => [GET] /api/v2/bgbooks => #23 | :get_api_v2_bgbooks
  :get_api_v3_bgbooks          => [GET] /api/v3/bgbooks => #25 | :get_api_v3_bgbooks
  :get_api_v3_bgbookdbs        => [GET] /api/v3/bgbookdbs => #67 | :get_api_v3_bgbookdbs
  :bgbooks_db_view_json        => [GET] /api/v3/bgbookdbs => billgatesbookdbs_view_sqlite | :bgbooks_db_view_json
  :intermediate_new            => [GET] /bgbook_db_intermediate/new => intermediate_new | :new_intermediate
  :intermediate_create         => [POST] /bgbook_db_intermediate/create => intermediate_create | :create_intermediate

```

The routes include both guides.

---
**HEADS-UP!**

The list of routes is an `OrderedCollection`. The order is the order of addition to the list
of routes, that is the order within the file.

However, when to match a route to the request of a particular webpage, the order is
reversed: if a user types an address, the route that will match will be sought from the last
of the list of routes.
---


Let's try things out. Input something and submit the form. If everything goes well a new
book will be persisted to the database – and it will be added at the bottom of the list of
books, and the browser should return to the page `/api/v3/bgbookdbs` and list the full list
of books.




---
*** HEADS-UP ***

If you want to go back to the original list of books, clean and reseed the database with:

```julia
julia> using BookDBs

julia> BookDBs.seed()
```
---

## Uploading files

Our app looks great -- but the list of books would be so much better if we'd display the
covers as well. Let's do it!

### Modify the database

The first thing we need to do is to modify our table to add a new column, for storing a
reference to the name of the cover image. Obviously, we'll use migrations:

```julia
julia> SearchLight.Generator.newmigration("add cover column")
[debug] New table migration created at db/migrations/2019030813344258_add_cover_column.jl
```

Now we need to edit the migration file - please make it look like this:

```julia
# db/migrations/*_add_cover_column.jl
module AddCoverColumn

import SearchLight.Migrations: add_column, add_index

# SQLite does not support column removal so the `remove_column` method is not implemented
# in the SearchLightSQLite adapter. If not using SQLite, add the following import
# import SearchLight.Migrations: remove_column

function up()
  add_column(:bookdbs, :cover, :string)
end

function down()
  # if using the SQLite backend, do not add the next line, it is not supported
  remove_column(:bookdbs, :cover)
end

end
```

Looking good - let's ask SearchLight to run it:

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

Perfect! Now we need to add the new column as a field to the `BookDBs.BookDB` model:

```julia
module BooDBs

using SearchLight, SearchLight.Validation, BooksValidator

export BookDB

Base.@kwdef mutable struct BookDB <: AbstractModel
  id::DbId = DbId()
  title::String = ""
  author::String = ""
  cover::String = ""
end

end
```

As a quick test we can extend our JSON view and see that all goes well - make it look like
this:

```julia
# app/resources/books/views/billgatesbookdbs_sqlite.json.jl
"Bill's Gates list of recommended books with a cover" => [
  Dict( "author" => b.author,
        "title" => b.title,
        "cover" => b.cover) for b in bookdbs]

```

If we navigate <http://localhost:8000/api/v3/bgbookdbs> you should see the newly added
"cover" property (empty, but present).

---
**HEADS-UP!**

Julia/Genie/Revise will fail to update `structs` on field changes. If you get an error
saying that `BookDB` does not have a `cover` field, please restart the Genie app.

---


### File uploading

Next step, extending our form to upload images (book covers). Let's create a new route, a
new controller function and a new view.

```julia
# route.jl
route(
  "/bgbook_db_intermediate/new_cover",
  BookDBsController.intermediate_new_cover;
  method = GET,
  named = :intermediate_new_cover)
```

```julia
# BookDBsController.jl
using Genie.Router, Genie.Renderer
function intermediate_new_cover()
  html(:bookdbs, :intermediate_form_new_cover)
end
```


```html
<!-- app/resources/books/views/intermediate_form_new_cover.jl.html -->
<h3>Add a new book recommended by Bill Gates with cover</h3>
<p>
  For inspiration you can visit <a href="https://www.gatesnotes.com/Books"
  target="_blank">Bill Gates' website</a>
</p>
<form action="$(Genie.Router.linkto(:create_intermediate_cover))"
      method="POST" enctype="multipart/form-data">
  <input type="text" name="book_title" placeholder="Book title" /><br />
  <input type="text" name="book_author" placeholder="Book author" /><br />
  <input type="file" name="book_cover" /><br />
  <input type="submit" value="Add book" />
</form>
```

The new bits are:

- a new attribute to our `<form>` tag: `enctype="multipart/form-data"`. This is required
  in order to support files payloads.
- a new input of type file: `<input type="file" name="book_cover" />`

You can see the updated form by visiting
<http://localhost:8000/bgbook_db_intermediate/new_cover>

Now, time to add a new book, with the cover! How about "Identity" by Francis Fukuyama?
Sounds good. You can use whatever image you want for the cover, or maybe borrow the one from
Bill Gates, I hope he won't mind
<https://www.gatesnotes.com/-/media/Images/GoodReadsBookCovers/Identity.png>. Just download
the file to your computer so you can upload it through our form.

Almost there - now to add the logic for handling the uploaded file server side with a new
route and a new controller function:


```julia
# route.jl
route(
  "/bgbook_db_intermediate/create_cover",
  BookDBsController.intermediate_create_cover;
  method = POST,
  named = :intermediate_create_cover)
```


```julia
# BookDBsController.jl
using Genie.Requests # to import filespayload()
function intermediate_create_cover()
  if haskey(filespayload(), "book_cover")
    load_name = String(filespayload("book_cover").name)

    web_path = joinpath("/img/covers", load_name)
    storage_path = joinpath("public/img/covers", load_name)

    # !!!! Please make sure that you create the folder `covers/` within `public/img/`
    open(storage_path; write = true, truncate = true) do f
      write(f, IOBuffer(filespayload("book_cover").data))
    end
  else
    web_path = ""
  end

  BookDB(title = params(:book_title), author = params(:book_author), cover = web_path) |>
    save && redirect(:bgbooks_db_view_json)
end
```


Also, very important, you need to make sure that `BooksDBController` is
`using Genie.Requests`.

Regarding the code, there's nothing very fancy about it. First we check if the files payload
contains an entry for our `book_cover` input. If yes, we compute the path where we want to
store the file, write the file, and store the path in the database.

**Please make sure that you create the folder `covers/` within `public/img/`**.

You can now check that the `cover` property is now outputted, as stored in the database:
<http://localhost:8000/api/v3/bgbookdbs>


### Display with pictures

Great, now let's display the images. Let's start with the HTML view - please edit
`app/resources/books/views/billgatesbooks.jl.html` and make sure it has the following
content:

```html
<!-- app/resources/books/views/intermediate_view_all_covers.jl.html -->
<h1>Bill's Gates top $( length(bookdbs) ) recommended books with cover pictures</h1>
<ul>
  <% for_each(bookdbs) do bookdb %>
    <li>
      <img src='$( isempty(bookdb.cover) ? "img/docs.png" : bookdb.cover )'
           width="100px" /> $(bookdb.title) by $(bookdb.author)</li>
    <% end %>
</ul>
```

Basically here we check if the `cover` property is not empty, and display the actual cover.
Otherwise we show a placeholder image.

Add a new route and controller:

```julia
# route.jl
route("/bgbook_db_intermediate/view_all_covers",
  BookDBsController.intermediate_view_all_covers;
  method = GET,
  named = :bgbooks_db_view_covers_html
)
```

```julia
# BookDBsController.jl
function intermediate_view_all_covers()
  html(:bookdbs, :intermediate_view_all_covers, bookdbs = all(BookDB))
end
```


You can now check the result at
<http://localhost:8000/bgbook_db_intermediate/view_all_covers>


Success, we're done here!


---
**HEADS-UP!**

In production you will have to make the upload code more robust - the big problem here is
that we store the cover file as it comes from the user which can lead to name clashes and
files being overwritten - not to mention security vulnerabilities. A more robust way would
be to compute a hash based on author and title and rename the cover to that.

---

## Partials

So far so good, but what if we want to update the books we have already uploaded? It would
be nice to add those missing covers. We need to add a bit of functionality to include
editing features.

First things first - let's add the routes. Please add these two new route definitions to the
`routes.jl` file:

```julia
# routes.jl
route(
  "/bgbook_db_intermediate/:id::Int/edit",
  BookDBsController.intermediate_edit;
  method = GET,
  named = :intermediate_edit_book
)

route(
  "/bgbook_db_intermediate/:id::Int/update",
  BooksController.intermediate_update;
  method = POST,
  named = :intermediate_update_book
)
```

We defined two new routes. The first will display the book object in the form, for editing.
The second will take care of actually updating the database, server side. For both routes we
need to pass the id of the book that we want to edit - and we want to constrain it to an
`Int`. We express this as the `/:id::Int/` part of the route.

We also want to:

- reuse the form which we have defined in
  `app/resources/books/views/intermediate_form_new.jl.html`
- make the form aware of whether it's used to create a new book, or for editing an existing
  one respond accordingly by setting the correct `action` pre-fill the inputs with the
  book's info when editing a book.

OK, that's quite a list and this is where things become interesting. This is an important
design pattern for CRUD web apps. So, are you ready, cause here is the trick: in order to
simplify the rendering of the form, we will always pass a book object into it. When editing
a book it will be the book corresponding to the `id` passed into the `route`. And when
creating a new book, it will be just an empty book object we'll create and then dispose of.

### Using view partials

First, let's set up the views. In `app/resources/books/views/` please create a new file
called `intermediate_partial_form.jl.html`. Then, from
`app/resources/books/views/intermediate_form_new.jl.html` cut the `<form>` code. That is,
everything starting from and ending at `<form>...</form>` tags (the code _including_ the
tags). Paste it into the newly created `intermediate_partial_form.jl.html` file. Now, create
a new file called `intermediate_partial_form.jl.html`, copy the entire content of
`intermediate_form_new.jl.html` and replace the previous `<form>...</form>` code
(_including_ the tags) with:

```julia
<% partial("app/resources/books/views/intermediate_partial_form.jl.html", context = @__MODULE__) %>
```

This line, as the `partial` function suggests, includes a view partial (i.e. snippet), which
is a part of a view file, effectively including a view within another view. Notice that
we're explicitly passing the `context` so Genie can set the correct variable scope when
including the partial.

After creating a new route and a new controller function, you can load the
`intermediate_form_new_partial` page on
<http://localhost:8000/bgbook_db_intermediate/intermediate_form_new_partial> to make sure
that everything still works with a new route and a new controller function:

```julia
# routes.jl
route(
  "/bgbook_db_intermediate/intermediate_form_new_partial",
  BookDBsController.intermediate_form_new_partial;
  method = GET,
  named = :intermediate_form_new_partial
)
```

```julia
# BookDBsController.jl
function intermediate_form_new_partial()
  html(:bookdbs, :intermediate_form_new_partial)
end
```

Now, let's add an Edit option to our list of books. Please go back to our list view file,
`billgatesbooks.jl.html`. Here, for each iteration, within the `for_each` block we'll want
to dynamically link to the edit page for the corresponding book.

#### `for_each` with view partials

However, this `for_each` which renders a Julia string is very ugly - and we now know how to
refactor it, by using a view partial. Let's do it. First, replace the body of the `for_each`
block:

```html
<!-- app/resources/books/views/billgatesbooks.jl.html -->
"""
<li>
  <img src='$( isempty(book.cover) ? "img/docs.png" : book.cover )'
       width="100px" /> $(book.title) by $(book.author)
</li>
"""
```

with:

```julia
partial("app/resources/books/views/book.jl.html", book = book, context = @__MODULE__)
```

Notice that we are using the `partial` function and we pass the book object into our view,
under the name `book` (will be accessible in `book` inside the view partial). Again, we're
passing the scope's `context` (our controller object).

Next, create the `book.jl.html` in `app/resources/books/views/`, for example with:

```julia
julia> touch("app/resources/books/views/book.jl.html")
```

Add this content to it:
TO BE CONTINUED


### View helpers

### Using Flax elements
