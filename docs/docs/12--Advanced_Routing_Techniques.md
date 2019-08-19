# Advanced routing techniques

Genie's router can be considered the brain of the app, matching web requests to functions, extracting and setting up the request's variables and the execution environment, and invoking the response methods. Such power is accompanied by a powerful set of features in regards to defining routes. Let's dive into these.

## Static routing

Starting with the simplest case, we can register "plain" routes by using the `route` method. The method takes as its required arguments the URI pattern and the function that should be invoked in order to provide the response. The router supports two ways of registering routes, either `route(pattern::String, f::Function)` or `route(f::Function, pattern::String)`. The first syntax is for passing function references -- while the second is for defining inline function.

### Example

The following snippet defines a function `greet` which returns the "Welcome to Genie!" string. We use the function as our route handler, by passing it as the second argument to the `route` method.

```julia
using Genie, Genie.Router

greet() = "Welcome to Genie!"

route("/greet", greet)          # [GET] /greet => greet

startup()
```

If you use your browser to navigate to <http://127.0.0.1:8000/greet> you'll see the code in action.

However, defining a dedicated handler function might be overkill for simple cases like this. As such, Genie allows registering in-line handlers:

```julia
route("/bye") do
  "Good bye!"
end                 # [GET] /bye => getfield(Main, Symbol("##3#4"))()
```

You can just navigate to <http://127.0.0.1:8000/bye> -- the route is instantly available in the app.

---
**HEADS UP**

The routes are added in the order in which they are defined but are matched from newest to oldest. This means that you can define a new route to overwrite a previously defined one.

Unlike Julia's multiple dispatch, Genie's router won't match by the most specific rule but by the first match. So if, for example, you register a route to match `/*`, it will handle all the requests, even if you have previously defined more specific routes. As a sidenote, you can use this technique to temporarely divert all users to a "Service Unavailable" page.

---

## Dynamic routing (using request/router parameters)

Static routing works great for fixed URLs. But what if we have dynamic URLs, where the components map to information in the backend (like database IDs) and vary with each request? For example, how would we handle a URL like "/customers/57943/orders/458230", where 57943 is the customer id and 458230 is the order id.

Such situations are handled through dynamic routing or route parameters. For the previous example, "/customers/57943/orders/458230", we can define a dynamic route as "/customers/:customer_id/orders/:order_id". Upon matching the request, the Router will unpack the values and expose them in the `@params` collection.

### Example

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "You asked for the order $(payload(:order_id)) for customer $(payload(:customer_id))"
end

startup()
```

## Routing methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`)

By default, routes are created to handle `GET` requests, since these are the most common. In order to define routes for handling other types of requests, we need to pass the `method` keyword argument, indicating the method. Genie's Router supports `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` methods.

The router defines and exports constansts for each of these as `Router.GET`, `Router.POST`, `Router.PUT`, `Router.PATCH`, `Router.DELETE`, and `Router.OPTIONS`.

### Example

We can setup the following `PATCH` route:

```julia
using Genie, Genie.Router, Genie.Requests

route("/patch_stuff", method = PATCH) do
  "Stuff to patch"
end

startup()
```

And we can test it using the `HTTP` package:

```julia
using HTTP

HTTP.request("PATCH", "http://127.0.0.1:8000/patch_stuff").body |> String
2019-08-19 14:23:46:INFO:Main: /patch_stuff 200

"Stuff to patch"
```

By executing a request with the `PATCH` method our route is triggered. Consequently, we access the response body and convert it to a string, which is "Stuff to patch", corresponding to our response.

## Named routes

Genie allows tagging routes with names. This is a very useful feature, to be used in conjunction with the `Router.tolink` method, in order to dynamically generate URLs to the routes. The advantage of this technique is that if we refer the route by name and generate the links dynamically, as long as the name stays the same, if we change the route, all the URLs will automatically point to the new route.

In order to name a route we need to use the `named` keyword argument, which expects a `Symbol`.

### Example

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id", named = :get_customer_order) do
  "Looking up order $(payload(:order_id)) for customer  $(payload(:customer_id))"
end         #  [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

We can check the status of our route with:

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

---
**HEADS UP**

For consistency, Genie names all the routes. However, the autogenerated name is state dependent. So, if you change the route, it's possible that the name will change as well. Thus, it's best to explicitly name the routes if you plan on referencing them throughout the app.

---

We can confirm this by adding an anonymous route:

```julia
route("/foo") do
  "foo"
end  #  [GET] /foo => getfield(Main, Symbol("##7#8"))()

julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

The new route has been automatically named `get_foo`, based on the method and URI pattern.

## Links to routes

We can use the name of the route to link back to it through the `linkto` method.

### Example

Let's start with the previously defined two routes:

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

Static routes such as `:get_foo` are straightforward to target:

```julia
julia> linkto(:get_foo)
"/foo"
```

For dynamic routes, it's a bit more involved as we need to supply the values for each of the parameters, as keyword arguments:

```julia
julia> linkto(:get_customer_order, customer_id = 1234, order_id = 5678)
"/customers/1234/orders/5678"
```

## Listing routes

At any time we can check which routes are registered with `Router.routes`:

```julia
julia> routes()
2-element Array{Genie.Router.Route,1}:
 [GET] /foo => getfield(Main, Symbol("##7#8"))()
 [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
```

Or, we can use the previously discussed `@routes` macro:

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##5#6"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##7#8"))()
```

### The `Route` type

The routes are represented internally by the `Route` type which has 3 fields:

* `method::String` - for storing the method of the route (`GET`, `POST`, etc)
* `path::String` - represents the URI pattern to be matched against
* `action::Function` - the route handler to be executed when the route is matched

## Removing routes

We can delete routes from the stack by calling the `delete!` method and passing the collection of routes and the name of the route to be removed. The method returns the collection of (remaining) routes

### Example

```julia
julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 2 entries:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()
  :get_foo            => [GET] /foo => getfield(Main, Symbol("##9#10"))()

julia> Router.delete!(@routes, :get_foo)
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()

julia> @routes
OrderedCollections.OrderedDict{Symbol,Genie.Router.Route} with 1 entry:
  :get_customer_order => [GET] /customers/:customer_id/orders/:order_id => getfield(Main, Symbol("##3#4"))()
```

## Matching routes by type of arguments

By default route parameters are parsed into the `payload` collection as `SubString{String}`:

```julia
using Genie, Genie.Router, Genie.Requests

route("/customers/:customer_id/orders/:order_id") do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end
```

This will output `Order ID has type SubString{String} // Customer ID has type SubString{String}`

However, for such a case, we'd very much prefer to receive our data as `Int` to avoid an explicit conversion -- _and_ to match only numbers. Genie supports such a workflow by allowing type annotatons to route parameters:

```julia
route("/customers/:customer_id::Int/orders/:order_id::Int", named = :get_customer_order) do
  "Order ID has type $(payload(:order_id) |> typeof) // Customer ID has type $(payload(:customer_id) |> typeof)"
end     #     [GET] /customers/:customer_id::Int/orders/:order_id::Int => getfield(Main, Symbol("##3#4"))()
```

Notice how we've added type annotations to `:customer_id` and `:order_id`.

However, attempting to access the URL `http://127.0.0.1:8000/customers/10/orders/20` will fail:

```julia
Failed to match URI params between Int64::DataType and 10::SubString{String}
MethodError(convert, (Int64, "10"), 0x00000000000063fe)
/customers/10/orders/20 404
```

As you can see, Genie attempts to convert the types from the default `SubString{String}` to `Int` -- but doesn't know how. It fails, can't find other matching routes and returns a `404 Not Found` response.

### Type conversion in routes

The error is easy to address though: we need to provide a type converter from `SubString{String}` to `Int`.

```julia
Base.convert(::Type{Int}, v::SubString{String}) = parse(Int, v)
```

Once we register the converter in `Base`, our request will be correctly handled, resulting in `Order ID has type Int64 // Customer ID has type Int64`

## The `@params` collection

It's good to know that the router bundles all the parameters of the current request into the `@params` collection (a `Dict{Symbol,Any}`). This contains valuable information, such as route parameters, query params, POST payload, the original HTTP.Request and HTTP.Response objects, etcetera. In general it's recommended not to access the `@params` collection directly but through the utility methods defined by `Genie.Requests` and `Genie.Responses` -- but knowing about `@params` might come in handy.
