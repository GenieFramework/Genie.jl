# Handling query params (GET variables)

Genie makes it easy to access query params: values sent as part of the URL. All the values are automatically collected by Genie and exposed in the `@params` collection (which is part of the `Router` module).

Here's a quick sample:

```julia
using Genie, Genie.Router

route("/hi") do
  name = haskey(@params, :name) ? @params(:name) : "Anon"
  "Hello $name"
end
```

If you access <http://127.0.0.1:8000/hi> the app will respond with "Hello Anon" since we're not passing any query params.

However, requesting <http://127.0.0.1:8000/hi?name=Adrian> will in turn display "Hello Adrian" as we're passing the `name` query variable with the value `Adrian`. This variable is exposed by Genie as `@params(:name)`.

## The `Requests` module

Genie provides a set of utilities for working with requests data within the `Requests` module. You can use the `getpayload` method to retrieve the query params as a `Dict{Symbol,Any}. We can rewrite the previous route to take advantage of this:

```julia
using Genie, Genie.Router, Genie.Requests

route("/hi") do
  "Hello $(getpayload(:name, "Anon"))"
end
```

The `getpayload` function has a few specializations, and one of them accepts the key and the default value. The default value is retuned if the `key` variable is not defined. You can see the various implementations for `getpayload` using the API docs or Julia's `help>` mode.