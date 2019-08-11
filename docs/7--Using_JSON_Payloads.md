# Using JSON payloads

A very common design patter, especially when developing REST APIs, is to accept JSON payloads sent as `application/json` `POST` data. Genie efficiently handles this situation through the utility function `Requests.jsonpayload`. Under the cover, Genie will process the `POST` request and will attempt to convert the text payload to a JSON object. If this fails, an error will be logged, but will not be thrown. If this happens you can still access the raw value (the payload not converted to JSON) by using the `Requests.rawpayload` method.

```julia
using HTTP
using Genie, Genie.Router, Genie.Requests, Genie.Renderer

route("/jsonpayload", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  json("Hello $(jsonpayload()["name"])")
end

startup()
```

Now, at the same REPL make a request using the `HTTP` package:

```julia
julia> HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json")], """{"name":"Adrian"}""")
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

First, with the two `@show` invokations, notice how `jsonpayload` had successfully converted the `POST` data to a `Dict`. While the `rawpayload` return the `POST` data as a `String`, exactly as received. And finally, our route handler returns a JSON response, greeting the user by extracting the name from within the `jsonpayload` `Dict`.
