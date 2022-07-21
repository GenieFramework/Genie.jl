# Developing a simple API backend

Genie makes it very easy to quickly set up a REST API backend. All it takes is a few lines of code. Add these to a `rest.jl` file:

```julia
# rest.jl
using Genie
import Genie.Renderer.Json: json

Genie.config.run_as_server = true

route("/") do
  (:message => "Hi there!") |> json
end

up()
```

The key bit here is `Genie.config.run_as_server = true`. This will start the server synchronously (blocking) so the `up()` function won't return (won't exit) keeping the Julia process running.
As an alternative, we can skip the `run_as_server = true` configuration and use `up(async = false)` instead.

The script can be run directly from the command line:

```shell
$ julia rest.jl
```

If you run the above code in the REPL, there is no need to set up `run_as_server = true` or `up(async = false)` because the REPL will keep the Julia process running.

## Accepting JSON payloads

One common requirement when exposing APIs is to accept `POST` payloads. That is, requests over `POST`, with a request body as a JSON encoded object. We can build an echo service like this:

```julia
using Genie, Genie.Renderer.Json, Genie.Requests
using HTTP

route("/echo", method = POST) do
  message = jsonpayload()
  (:echo => (message["message"] * " ") ^ message["repeat"]) |> json
end

route("/send") do
  response = HTTP.request("POST", "http://localhost:8000/echo", [("Content-Type", "application/json")], """{"message":"hello", "repeat":3}""")

  response.body |> String |> json
end

up(async = false)
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
