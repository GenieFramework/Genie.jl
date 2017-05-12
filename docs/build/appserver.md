

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='AppServer.startup' href='#AppServer.startup'>#</a>
**`AppServer.startup`** &mdash; *Function*.



```
startup(port::Int = 8000) :: Void
```

Starts the web server on the configurated port. Automatically invoked when Genie is started with the `s` or the `server:start` command line params. Can be manually invoked from the REPL as well, when starting Genie without the above params – ideally `async` to allow reusing the REPL session.

**Examples**

```julia
julia> @spawn AppServer.startup()
Listening on 0.0.0.0:8000...
Future(1,1,1,Nullable{Any}())
```


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L8-L21' class='documenter-source'>source</a><br>

<a id='AppServer.handle_connect' href='#AppServer.handle_connect'>#</a>
**`AppServer.handle_connect`** &mdash; *Function*.



```
handle_connect(client::HttpServer.Client) :: Void
```

Connection callback for HttpServer. Stores the Request IP in the current task's local storage.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L74-L78' class='documenter-source'>source</a><br>

<a id='AppServer.handle_request' href='#AppServer.handle_request'>#</a>
**`AppServer.handle_request`** &mdash; *Function*.



```
handle_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response
```

HttpServer handler function - invoked when the server gets a request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L95-L99' class='documenter-source'>source</a><br>

<a id='AppServer.sign_response!' href='#AppServer.sign_response!'>#</a>
**`AppServer.sign_response!`** &mdash; *Function*.



```
sign_response!(res::Response) :: Response
```

Adds a signature header to the response using the value in `Genie.config.server_signature`. If `Genie.config.server_signature` is empty, the header is not added.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L126-L131' class='documenter-source'>source</a><br>

<a id='AppServer.log_request' href='#AppServer.log_request'>#</a>
**`AppServer.log_request`** &mdash; *Function*.



```
log_request(req::Request) :: Void
```

Logs information about the request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L141-L145' class='documenter-source'>source</a><br>

<a id='AppServer.log_response' href='#AppServer.log_response'>#</a>
**`AppServer.log_response`** &mdash; *Function*.



```
log_response(req::Request, res::Response) :: Void
```

Logs information about the response.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L157-L161' class='documenter-source'>source</a><br>

<a id='AppServer.log_request_response' href='#AppServer.log_request_response'>#</a>
**`AppServer.log_request_response`** &mdash; *Function*.



```
log_request_response(req_res::Union{Request,Response}) :: Void
```

Helper function that logs `Request` or `Response` objects.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L173-L177' class='documenter-source'>source</a><br>

<a id='AppServer.parse_inner_dict' href='#AppServer.parse_inner_dict'>#</a>
**`AppServer.parse_inner_dict`** &mdash; *Function*.



```
parse_inner_dict{K,V}(d::Dict{K,V}) :: Dict{String,String}
```

Helper function that knows how to parse a `Dict` containing `Request` or `Response` data and prepare it for being logged.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/AppServer.jl#L203-L207' class='documenter-source'>source</a><br>

