### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ e6106427-6fb1-4a3f-a556-dc60d190ca20
# hideall

using Genie,Genie.Router;

# ╔═╡ 95cc40c3-7b57-4b54-b80b-0b57fa0e347f
# hideall

using Genie.Requests  # Genie and Genie.Router already imported above

# ╔═╡ 43a9d450-3269-11ec-2353-1b13386fbc8d
md"""
# Advanced routing techniques

Genie's router can be considered the brain of the app, matching web requests to functions, extracting and setting up the request's variables and the execution environment, and invoking the response methods. Such power is accompanied by a powerful set of features for defining routes. Let's dive into these.

"""

# ╔═╡ 3427c72a-a73c-4cb9-a0f1-4ae6671394a3
md"""

## Static routing

Starting with the simplest case, we can register "plain" routes by using the `route` method. The method takes as its required arguments the URI pattern and the function that should be invoked in order to provide the response. The router supports two ways of registering routes, either `route(pattern::String, f::Function)` or `route(f::Function, pattern::String)`. The first syntax is for passing function references -- while the second is for defining inline function.
"""

# ╔═╡ 9bb74978-18b7-42f3-9fd7-b25c1ce676de
md"""

### Example

The following snippet defines a function `greet` which returns the "Welcome to Genie!" string. We use the function as our route handler, by passing it as the second argument to the `route` method.
"""

# ╔═╡ e00bd027-f54e-46c8-acb9-b031b3f06f1b
md"""

```julia
julia> using Genie, Genie.Router

julia> greet() = "Welcome to Genie!"

julia> route("/greet", greet)          # [GET] /greet => greet

julia> up() # start the server
```
"""

# ╔═╡ 452263da-3412-4356-b336-9161d22f8ac3
# hideall

greet() = "Welcome to Genie!";

# ╔═╡ c50433e6-1bb1-434f-9924-3446ecaa0a95
# hideall

route("/greet", greet)

# ╔═╡ 7cc2446e-3e17-4b23-b2aa-c3d754889550
# hideall

up(); # start the server

# ╔═╡ 6746b8e6-8ae7-4cae-84a6-13bff5b17863
# hideall

down(); # stop the server

# ╔═╡ 2234a9ac-150b-41dd-aefc-d46d96f69761
md"""
If you use your browser to navigate to <http://127.0.0.1:8000/greet> you'll see the code in action.

However, defining a dedicated handler function might be overkill for simple cases like this. As such, Genie allows registering in-line handlers:
"""

# ╔═╡ 95de3f62-6428-4c17-aafd-173892eafa9e
md"""

```julia
route("/bye") do
	"Good bye!"
end
```
"""

# ╔═╡ 02234d5a-0cb9-4687-9a2b-af1036b8a126
# hideall

route("/bye") do
	"Good bye!"
end # # [GET] /bye => getfield(Main, Symbol("##3#4"))()

# ╔═╡ d4e34ce0-f2f8-4f1d-b06c-fb5ecb5d84c4
# hideall

up(); 

# ╔═╡ dc0e4134-d611-48ab-a344-42b7b4ce7e54
# hideall

down();

# ╔═╡ 5dcd29af-b256-42c1-b4c0-13c1b003b142
md"""
You can just navigate to <http://127.0.0.1:8000/bye> -- the route is instantly available in the app.
"""

# ╔═╡ dd3692e0-bf7b-4174-8619-011b732f4700
md"""
---
**HEADS UP**

The routes are added in the order in which they are defined but are matched from newest to oldest. This means that you can define a new route to overwrite a previously defined one.

Unlike Julia's multiple dispatch, Genie's router won't match the most specific rule, but the first matching one. So if, for example, you register a route to match `/*`, it will handle all the requests, even if you have previously defined more specific routes. As a side-note, you can use this technique to temporarily divert all users to a maintenance page.

---
"""

# ╔═╡ fb90d39c-03fb-453f-bc71-cefde15b7189
md"""
## Dynamic routing (using route parameters)

Static routing works great for fixed URLs. But what if we have dynamic URLs, where the components map to information in the backend (like database IDs) and vary with each request? For example, how would we handle a URL like "/customers/57943/orders/458230", where 57943 is the customer id and 458230 is the order id.

Such situations are handled through dynamic routing or route parameters. For the previous example, "/customers/57943/orders/458230", we can define a dynamic route as "/customers/:customer_id/orders/:order_id". Upon matching the request, the Router will unpack the values and expose them in the `params` collection.

### Example
"""

# ╔═╡ 4bdafae5-426b-4735-b0ba-57ad82d8a8cb
md"""

```julia

using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "You asked for the order $(payload(:order_id)) for customer $(payload(:customer_id))"
end

up()
```
"""

# ╔═╡ 2345f769-cf5f-421d-9237-a86d79f470a8
# hideall

route("/customers/:customer_id/orders/:order_id") do
	"You asked for the order $(payload(:order_id)) for customer $(payload(:customer_id))"
end;

# ╔═╡ 98a2f767-3605-420e-89af-5b1d974465e0
md"""
you can type something like this in browser to verify

http://127.0.0.1:8000/customers/34234234234/orders/34burger_discount
"""

# ╔═╡ 586e9672-5878-457f-aad7-24ac0173b550
# hideall

up();

# ╔═╡ 8af441f4-d446-4881-af93-b38ea3390916
# hideall

down();

# ╔═╡ cda56305-7c53-4a05-8dd8-56d4edf06369
md"""

## Routing methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`)

By default, routes handle `GET` requests, since these are the most common. In order to define routes for handling other types of request methods, we need to pass the `method` keyword argument, indicating the HTTP method. Genie's Router supports `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` methods.

The router defines and exports constants for each of these as `Router.GET`, `Router.POST`, `Router.PUT`, `Router.PATCH`, `Router.DELETE`, and `Router.OPTIONS`.

"""

# ╔═╡ 1d6a2d14-5f98-4503-b756-6128b62b1bea
md"""

### Example

We can setup the following `PATCH` route:
"""

# ╔═╡ 8b243b7f-5a3d-4809-9dce-e21b0e16d5e7
md"""

```julia
using Genie, Genie.Router, Genie.Requests

route("/patch_stuff", method = PATCH) do
  "Stuff to patch"
end

up()
```
"""

# ╔═╡ 03e98ab3-712b-49e5-9c28-381df88e7eb1
# hideall

route("/patch_stuff", method= PATCH) do
	"Stuff to patch"
end;

# ╔═╡ af21fd1b-b06a-4193-95e1-9a97c7fe9f7a
# hideall

up();

# ╔═╡ 14eb943e-b7e1-41b8-84d1-7cbf0b47b22c
md"""
And we can test it using `HTTP` package:

```julia
julia> using HTTP

julia> HTTP.request("PATCH", "http://127.0.0.1:8000/patch_stuff").body |> String
2019-08-19 14:23:46:INFO:Main: /patch_stuff 200
```

"""

# ╔═╡ 1e388f30-bd1d-4cab-96ce-98c98e2f0c21
# hideall

#using HTTP;

# ╔═╡ daaac609-bd82-42e9-bd15-998fef170746
# hideall

#HTTP.request("PATCH", "http://127.0.0.1:8000/patch_stuff").body |> String

# ╔═╡ 9eee3b60-65df-4312-bfbf-402f5efdbb43
# hideall

down();

# ╔═╡ 330f8fa5-6b91-488b-960d-58591c593c79
md"""
By sending a request with the `PATCH` method, our route is triggered. Consequently, we access the response body and convert it to a string, which is "Stuff to patch", corresponding to our response.

### Named routes

Genie allows tagging routes with names. This is a very powerful feature, to be used in conjunction with the `Router.tolink` method, for dynamically generating URLs towards the routes. The advantage of this technique is that if we refer the route by name and generate the links dynamically using `tolink`, as long as the name of the route stays the same, if we change the route pattern, all the URLs will automatically match the new route definiton.

In order to name a route we need to use the `named` keyword argument, which expects a `Symbol`.

### Example
"""

# ╔═╡ baf44a2a-bbc3-463a-ac8e-9879b1e6e843
md"""

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id", named = :get_customer_order) do
  "Looking up order $(payload(:order_id)) for customer  $(payload(:customer_id))"
end
```
"""

# ╔═╡ 6e38af88-fe97-42e6-a821-9f7ace5938bf
# hideall

route("/customers/:customer_id/orders/:order_id", named = :get_customer_order) do
	"Looking up order $(payload(:order_id)) for customer $(payload(:customer_id))"
end; #  [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()

# ╔═╡ 8347e271-01ad-4bb6-aee3-048884250296
md"""
We can check the status of our route with:
"""

# ╔═╡ 319ec0d0-c372-4494-b14f-82c6b0ec1521
md"""

```julia
julia> Genie.Router.routes()
```
"""

# ╔═╡ 13816d4c-5bcc-4b6b-b185-736ad311af8f
# hideall

Genie.Router.routes()

# ╔═╡ 3c95a47d-0847-4cae-b9e0-20461a90d41f
md"""

---
**HEADS UP**

For consistency, Genie names all the routes. However, the auto-generated name is state dependent. So, if you change the route, it's possible that the name will change as well. Thus, it's best to explicitly name the routes if you plan on referencing them throughout the app.

---

We can confirm this by adding an anonymous route:

"""

# ╔═╡ daf764d0-7b41-46e6-a2e7-df7692246c40
# hideall

route("/foo") do
	"foo"
end;

# ╔═╡ 4de5ee94-67c5-45ad-8faf-2eee9085d214
md"""

```julia
route("/foo") do
  "foo"
end  #  [GET] /foo => getfield(Main, Symbol("##7#8"))()

julia> Genie.Router.routes()
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```
"""

# ╔═╡ 06615877-44a6-4dfc-87ec-dba8b9b50923
md"""
The new route has been automatically named `get_foo`, based on the method and URI pattern.

### Links to routes

We can use the name of the route to link back to it through the `linkto` method.

### Example

Let's start with the previously defined two routes:

```julia
julia> Genie.Router.routes()
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```
"""

# ╔═╡ 05db4144-2b1c-4262-8dc8-d4dd5cfb786f
md"""
Static routes such as `:get_foo` are straightforward to target:
"""

# ╔═╡ 5b711e10-58bc-4e52-bf69-c3bb71816ac6
md"""

```julia
julia> linkto(:get_foo)
```
"""

# ╔═╡ ea097103-c7ef-4873-991c-1f2747c1e388
# hideall

linkto(:get_foo)

# ╔═╡ 0c2548e6-c289-4d77-8ad3-d655a6af6197
md"""
For dynamic routes, it's a bit more involved as we need to supply the values for each of the parameters, as keyword arguments:
"""

# ╔═╡ 654595db-c64d-4ecd-b035-c4019a18aa05
md"""

```julia
julia> linkto(:get_customer_order, customer_id = 1234, order_id = 5678)
```
"""

# ╔═╡ f2630c63-e33c-4395-8670-fe7c053f3951
# hideall

linkto(:get_customer_order, customer_id = 1234, order_id = 5678)

# ╔═╡ 8a3d030f-d89d-4e95-97c0-f2ae895f68a4
md"""
The `linkto` should be used in conjunction with the HTML code for generating links, ie:

```
<a href="$(linkto(:get_foo))">Foo</a>
```
"""

# ╔═╡ 41d29f5a-e3f2-4b38-898d-4bc9efa27c92
md"""

## Listing routes

At any time we can check which routes are registered with `Router.routes`:
"""

# ╔═╡ 6928b47a-2d53-4a48-b330-10b4cd078247
md"""

```julia
julia> Genie.Router.routes();
```
"""

# ╔═╡ b5f1cfa6-a60c-4b2d-a8c7-73d14bff5873
# hideall

routes()

# ╔═╡ ff337fb2-ce52-4e4e-ac81-eef3fe964ce5
md"""

### The `Route` type

The routes are represented internally by the `Route` type which has 4 fields:

* `method::String` - for storing the method of the route (`GET`, `POST`, etc)
* `path::String` - represents the URI pattern to be matched against
* `action::Function` - the route handler to be executed when the route is matched
* `name::Union{Symbol,Nothing}` - the name of the route

## Removing routes

We can delete routes from the stack by calling the `delete!` method and passing the collection of routes and the name of the route to be removed. The method returns the collection of (remaining) routes

### Example
"""

# ╔═╡ b5b552b4-6b2a-419e-8276-8335b678871d
md"""
Listing all routes:
"""

# ╔═╡ 7e3a3909-d2a7-456b-955e-7545e6f7db4c
md"""

```julia
julia> routes()
```

"""

# ╔═╡ 694be0b4-1c62-4386-913b-f64f7aa1911c
# hideall

routes()

# ╔═╡ 160f18a8-6819-4e02-a238-4a3c257d55d4
md"""
Deleting route:

```julia
julia> Router.delete!(:get_foo)
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()
```
"""

# ╔═╡ ee82e180-62cd-4c06-b415-7be50677d654
md"""
## Matching routes by type of arguments

By default route parameters are parsed into the `payload` collection as `SubString{String}`:

"""

# ╔═╡ 36040f4c-74b1-4c4d-a115-88e2ec573a03
md"""

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/new/:customer_id/orders/:order_id") do
	"Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end
```
"""

# ╔═╡ 97dc0184-090b-458d-b2e9-ee6750779a50
# hideall

route("/customers/new/:customer_id/orders/:order_id") do
	"Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end;

# ╔═╡ f5b121a4-46e2-48c7-9c86-47acaafb2c5b
md"""
This will output `Order ID has type SubString{String} // Customer ID has type SubString{String}`

However, for such a case, we'd very much prefer to receive our data as `Int` to avoid an explicit conversion -- _and_ to match only numbers. Genie supports such a workflow by allowing type annotations to route parameters:

"""

# ╔═╡ 380649f1-e194-4c3b-8e9c-5643b58a2300
route("/customers/newtwo/:customer_id::Int/orders/:order_id::Int", named= :get_customer_order) do
	"Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end;

# ╔═╡ 64ef981f-befe-4f5d-bd89-e95a95c3a8e7
md"""

```julia
julia> HTTP.request("GET", "http://127.0.0.1:8000/customers/newtwo/34234/orders/24")
```
"""

# ╔═╡ 96f18f32-9b5f-42e4-8d65-652754da73d3
md"""Notice how we've added type annotations to `:customer_id` and `:order_id` in the form `:customer_id::Int` and `:order_id::Int`.

"""

# ╔═╡ a4db6b7b-1cec-4096-a74a-08f177e77880
md"""
However, attempting to access the URL `http://127.0.0.1:8000/customers/10/orders/20` will fail:

```julia
Failed to match URI params between Int64::DataType and 10::SubString{String}
MethodError(convert, (Int64, "10"), 0x00000000000063fe)
/customers/10/orders/20 404
```

As you can see, Genie attempts to convert the types from the default `SubString{String}` to `Int` – but doesn't know how. It fails, can't find other matching routes and returns a `404 Not Found` response.


"""

# ╔═╡ 8111a773-6568-47e1-90c6-c63a3f193921
md"""
### Type conversion in routes

The error is easy to address though: we need to provide a type converter from `SubString{String}` to `Int`.

```julia
Base.convert(::Type{Int}, v::SubString{String}) = parse(Int, v)
```

Once we register the converter in `Base`, our request will be correctly handled, resulting in `Order ID has type Int64 // Customer ID has type Int64`
"""

# ╔═╡ 2d995a3b-9739-427b-9280-0f7ea6c3a352
md"""
## Matching individual URI segments

Besides matching the full route, Genie also allows matching individual URI segments. That is, enforcing that the various route parameters obey a certain pattern. In order to introduce constraints for route parameters we append `#pattern` at the end of the route parameter.

### Example

For instance, let's assume that we want to implement a localized website where we have a URL structure like: `mywebsite.com/en`, `mywebsite.com/es`, `mywebsite.com/in` and `mywebsite.com/de`. We can define a dynamic route and extract the locale variable to serve localized content:

```julia
route(":locale", TranslationsController.index)
```

This will work very well, matching requests and passing the locale into our code within the `payload(:locale)` variable. However, it will also be too greedy, virtually matching all the requests, including things like static files (ie `mywebsite.com/favicon.ico`). We can constrain what the `:locale` variable can match, by appending the pattern (a regex pattern):

```julia
route(":locale#(en|es|de)", TranslationsController.index)
```

---
**HEADS UP**

Keep in mind not to duplicate application logic. For instance, if you have an array of supported locales, you can use that to dynamically generate the pattern -- routes can be fully dynamically generated!

```julia
const LOCALE = ":locale#($(join(TranslationsController.AVAILABLE_LOCALES, '|')))"

route("/$LOCALE", TranslationsController.index, named = :get_index)
```

---

## The `params` collection

It's good to know that the router bundles all the parameters of the current request into the `params` collection (a `Dict{Symbol,Any}`). This contains valuable information, such as route parameters, query params, POST payload, the original HTTP.Request and HTTP.Response objects, etc. In general it's recommended not to access the `params` collection directly but through the utility methods defined by `Genie.Requests` and `Genie.Responses` -- but knowing about `params` might come in handy for advanced users.
"""

# ╔═╡ ec5f638b-8877-470d-9368-d5a13da98d38
# hideall

down();

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"

[compat]
Genie = "~4.9.1"
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

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

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

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

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

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

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

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

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
# ╟─43a9d450-3269-11ec-2353-1b13386fbc8d
# ╟─3427c72a-a73c-4cb9-a0f1-4ae6671394a3
# ╟─9bb74978-18b7-42f3-9fd7-b25c1ce676de
# ╟─e00bd027-f54e-46c8-acb9-b031b3f06f1b
# ╠═e6106427-6fb1-4a3f-a556-dc60d190ca20
# ╠═452263da-3412-4356-b336-9161d22f8ac3
# ╠═c50433e6-1bb1-434f-9924-3446ecaa0a95
# ╠═7cc2446e-3e17-4b23-b2aa-c3d754889550
# ╠═6746b8e6-8ae7-4cae-84a6-13bff5b17863
# ╟─2234a9ac-150b-41dd-aefc-d46d96f69761
# ╟─95de3f62-6428-4c17-aafd-173892eafa9e
# ╠═02234d5a-0cb9-4687-9a2b-af1036b8a126
# ╠═d4e34ce0-f2f8-4f1d-b06c-fb5ecb5d84c4
# ╠═dc0e4134-d611-48ab-a344-42b7b4ce7e54
# ╟─5dcd29af-b256-42c1-b4c0-13c1b003b142
# ╟─dd3692e0-bf7b-4174-8619-011b732f4700
# ╟─fb90d39c-03fb-453f-bc71-cefde15b7189
# ╟─4bdafae5-426b-4735-b0ba-57ad82d8a8cb
# ╠═95cc40c3-7b57-4b54-b80b-0b57fa0e347f
# ╠═2345f769-cf5f-421d-9237-a86d79f470a8
# ╟─98a2f767-3605-420e-89af-5b1d974465e0
# ╠═586e9672-5878-457f-aad7-24ac0173b550
# ╠═8af441f4-d446-4881-af93-b38ea3390916
# ╟─cda56305-7c53-4a05-8dd8-56d4edf06369
# ╟─1d6a2d14-5f98-4503-b756-6128b62b1bea
# ╟─8b243b7f-5a3d-4809-9dce-e21b0e16d5e7
# ╠═03e98ab3-712b-49e5-9c28-381df88e7eb1
# ╠═af21fd1b-b06a-4193-95e1-9a97c7fe9f7a
# ╟─14eb943e-b7e1-41b8-84d1-7cbf0b47b22c
# ╠═1e388f30-bd1d-4cab-96ce-98c98e2f0c21
# ╠═daaac609-bd82-42e9-bd15-998fef170746
# ╠═9eee3b60-65df-4312-bfbf-402f5efdbb43
# ╟─330f8fa5-6b91-488b-960d-58591c593c79
# ╟─baf44a2a-bbc3-463a-ac8e-9879b1e6e843
# ╠═6e38af88-fe97-42e6-a821-9f7ace5938bf
# ╟─8347e271-01ad-4bb6-aee3-048884250296
# ╟─319ec0d0-c372-4494-b14f-82c6b0ec1521
# ╠═13816d4c-5bcc-4b6b-b185-736ad311af8f
# ╟─3c95a47d-0847-4cae-b9e0-20461a90d41f
# ╠═daf764d0-7b41-46e6-a2e7-df7692246c40
# ╟─4de5ee94-67c5-45ad-8faf-2eee9085d214
# ╟─06615877-44a6-4dfc-87ec-dba8b9b50923
# ╟─05db4144-2b1c-4262-8dc8-d4dd5cfb786f
# ╟─5b711e10-58bc-4e52-bf69-c3bb71816ac6
# ╠═ea097103-c7ef-4873-991c-1f2747c1e388
# ╟─0c2548e6-c289-4d77-8ad3-d655a6af6197
# ╟─654595db-c64d-4ecd-b035-c4019a18aa05
# ╠═f2630c63-e33c-4395-8670-fe7c053f3951
# ╟─8a3d030f-d89d-4e95-97c0-f2ae895f68a4
# ╟─41d29f5a-e3f2-4b38-898d-4bc9efa27c92
# ╟─6928b47a-2d53-4a48-b330-10b4cd078247
# ╠═b5f1cfa6-a60c-4b2d-a8c7-73d14bff5873
# ╟─ff337fb2-ce52-4e4e-ac81-eef3fe964ce5
# ╟─b5b552b4-6b2a-419e-8276-8335b678871d
# ╟─7e3a3909-d2a7-456b-955e-7545e6f7db4c
# ╠═694be0b4-1c62-4386-913b-f64f7aa1911c
# ╟─160f18a8-6819-4e02-a238-4a3c257d55d4
# ╟─ee82e180-62cd-4c06-b415-7be50677d654
# ╟─36040f4c-74b1-4c4d-a115-88e2ec573a03
# ╠═97dc0184-090b-458d-b2e9-ee6750779a50
# ╟─f5b121a4-46e2-48c7-9c86-47acaafb2c5b
# ╠═380649f1-e194-4c3b-8e9c-5643b58a2300
# ╟─64ef981f-befe-4f5d-bd89-e95a95c3a8e7
# ╟─96f18f32-9b5f-42e4-8d65-652754da73d3
# ╟─a4db6b7b-1cec-4096-a74a-08f177e77880
# ╟─8111a773-6568-47e1-90c6-c63a3f193921
# ╟─2d995a3b-9739-427b-9280-0f7ea6c3a352
# ╠═ec5f638b-8877-470d-9368-d5a13da98d38
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
