# Developing a simple API backend

Genie makes it very easy to quickly set up a REST API backend. All it takes is a few lines of code:

```julia
using Genie
import Genie.Router: route
import Genie.Renderer.Json: json

Genie.config.run_as_server = true

route("/") do
  (:message => "Hi there!") |> json
end

Genie.startup()
```

The key bit here is `Genie.config.run_as_server = true`. This will start the server synchronously so the `startup()` function won't return.
This endpoint can be run directly from the command line - if say, you save the code in a `rest.jl` file:

```shell
$ julia rest.jl
```

## Accepting JSON payloads

One common requirement when exposing APIs is to accept `POST` payloads. That is, requests over `POST`, with a request body, usually as a JSON encoded object. We can build an echo service like this:

```julia
using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using HTTP

route("/echo", method = POST) do
  message = jsonpayload()
  (:echo => (message["message"] * " ") ^ message["repeat"]) |> json
end

route("/send") do
  response = HTTP.request("POST", "http://localhost:8000/echo", [("Content-Type", "application/json")], """{"message":"hello", "repeat":3}""")

  response.body |> String |> json
end

Genie.startup(async = false)
```

Here we define two routes, `/send` and `/echo`. The `send` route makes a `HTTP` request over `POST` to `/echo`, sending a JSON payload with two values, `message` and `repeat`.
In the `/echo` route, we grab the JSON payload using the `Requests.jsonpayload()` function, extract the values from the JSON object, and output the `message` value repeated for a number of times equal to the `repeat` value.

If you run the code, the output should be

```javascript
{
  echo: "hello hello hello "
}
```

If the payload contains invalid JSON, the `jsonpayload` will be set to `nothing`. You can still access the raw payload by using the `Requests.rawpayload()` function.
You can also use `rawpayload` if for example the type of request/payload is not JSON.
