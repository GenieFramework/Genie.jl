# Using JSON payloads

A very common design pattern, especially when developing REST APIs, is to accept JSON payloads sent as `application/json` data over `POST` requests. Genie efficiently handles this use case through the utility function `Requests.jsonpayload`. Under the cover, Genie will process the `POST` request and will attempt to parse the JSON text payload. If this fails, you can still access the raw data (the text payload not converted to JSON) by using the `Requests.rawpayload` method.

### Example

```julia
using Genie, Genie.Router, Genie.Requests, Genie.Renderer

route("/jsonpayload", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  json("Hello $(jsonpayload()["name"])")
end

up()
```

Next we make a `POST` request using the `HTTP` package:

```julia
using HTTP

HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json")], """{"name":"Adrian"}""")
```

We will get the following output:

```julia
jsonpayload() = Dict{String,Any}("name"=>"Adrian")
rawpayload() = "{\"name\":\"Adrian\"}"

INFO:Main: /jsonpayload 200

HTTP.Messages.Response:
"""
HTTP/1.1 200 OK
Content-Type: application/json
Transfer-Encoding: chunked

"Hello Adrian""""
```

First, for the two `@show` calls, notice how `jsonpayload` had successfully converted the `POST` data to a `Dict`. While the `rawpayload` returns the `POST` data as a `String`, exactly as received. Finally, our route handler returns a JSON response, greeting the user by extracting the name from within the `jsonpayload` `Dict`.
