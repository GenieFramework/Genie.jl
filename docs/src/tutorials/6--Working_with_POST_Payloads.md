# Reading POST payloads

Genie makes it easy to work with `POST` data. First, we need to register a dedicated route to handle `POST` requests.
Then, when a `POST` request is received, Genie will automatically extract the payload, making it accessible throughout
the `Requests.postpayload` method -- and appending it to the `Router.params(:POST)` collection.

## Handling `form-data` payloads

The following snippet registers two routes in the root of the app, one for `GET` and the other for `POST` requests.
The `GET` route displays a form which submits over `POST` to the other route. Finally, upon receiving the data,
we display a message.

### Example

```julia
using Genie, Genie.Renderer.Html, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="name" value="" placeholder="What's your name?" />
  <input type="submit" value="Greet" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  "Hello $(postpayload(:name, "Anon"))"
end

up()
```

The `postpayload` function has a few specializations, and one of them accepts the key and the default value. The default
value is returned if the `key` variable is not defined. You can see the various implementations for `postpayload` using
the API docs or Julia's `help>` mode.
