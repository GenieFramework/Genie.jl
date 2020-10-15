# Working with Web Sockets

Genie provides a powerful workflow for client-server communication over websockets. The system hides away the complexity of the network level communication, exposing powerful abstractions which resemble Genie's familiar MVC workflow: the clients and the server exchange messages over `channels` (which are the equivalent of `routes`).

## Registering `channels`

The messages are mapped to a matching channel, where are processed by Genie's `Router` which extracts the payload and invokes the designated handler (controller method or function). For most purposes, the `channels` are the functional equivalents of `routes` and are defined in the same way:

```julia
using Genie.Router

channel("/foo/bar") do
  # process request
end

channel("/baz/bax", YourController.your_handler)
```

The above `channel` definitions will handle websocket messages sent to `/foo/bar` and `/baz/bax`.

## Setting up the client

In order to enable WebSockets communication in the browser we need to load a JavaScript file. This is provided by Genie, through the `Assets` module. Genie makes it extremely easy to setup the WebSockets infrastructure on the client side, by providing the `Assets.channels_support()` method. For instance, if we want to add support for WebSockets to the root page of a web app, all we need is this:

```julia
using Genie.Router, Genie.Assets

route("/") do
  Assets.channels_support()
end
```

Literally, that is all we need in order to be able to push and receive messages between client and server.

---

## Try it!

You can follow through by running the following Julia code in a Julia REPL:

```julia
using Genie, Genie.Router, Genie.Assets

Genie.config.websockets_server = true # enable the websockets server

route("/") do
  Assets.channels_support()
end

up() # start the servers
```

Now if you visit <http://localhost:8000> you'll get a blank page -- which, however, includes all the necessary functionality for WebSockets communication! If you use the browser's developer tools, the Network pane will indicate that a `channels.js` file was loaded and that a WebSockets request was made (Status 101 over GET). Additionally, if you peek at the Console, you will see a `Subscription ready` message. The output in the console should be something like:

```text
Queuing subscription channels.js:107:13
Subscription ready channels.js:105:13
OK channels.js:74:11
Overwrite window.parse_payload to handle messages from the server channels.js:98:11
OK
```

** What happened? **

At this point, by invoking `Assets.channels_support()`, Genie has done the following:

* loaded the bundled the `channels.js` file which provides a JS API for communicating over WebSockets
* has created two default channels, for subscribing and unsubscribing: `/__/subscribe` and `/__/unsubscribe`
* has invoked `/__/subscribe` and created a WebSockets connection between client and server

### Pushing messages from the server

We are ready to interact with the client. Go to the Julia REPL running the web app and run:

```julia
julia> Genie.WebChannels.connected_clients()
1-element Array{Genie.WebChannels.ChannelClient,1}:
 Genie.WebChannels.ChannelClient(HTTP.WebSockets.WebSocket{HTTP.ConnectionPool.Transaction{Sockets.TCPSocket}}(T0  🔁    0↑🔒    0↓🔒 100s 127.0.0.1:8001:8001 ≣16, 0x01, true, UInt8[0x7b, 0x22, 0x63, 0x68, 0x61, 0x6e, 0x6e, 0x65, 0x6c, 0x22  …  0x79, 0x6c, 0x6f, 0x61, 0x64, 0x22, 0x3a, 0x7b, 0x7d, 0x7d], UInt8[], false, false), ["__"])
```

We have one connected client to the `__` channel! We can send it a message:

```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
true
```

If you look in the browser's console you will see the "Hey!" message! By default, the client side handler simply outputs the message. We're also informed that we can "Overwrite window.parse_payload to handle messages from the server". Let's do it. Run this in the current REPL (it will overwrite our root route handler):

```julia
route("/") do
  Assets.channels_support() *
  """
  <script>
  window.parse_payload = function(payload) {
    console.log('Got this payload: ' + payload);
  }
  </script>
  """
end
```

Now if you reload the page and broadcast the message, it will be picked up by our custom payload handler. However, chances are you'll also get an error when broadcasting (don't worry though, the error is just logged, it's not breaking the application as it's not critical):

```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
┌ Error: Base.IOError("stream is closed or unusable", 0)
└ @ Genie.WebChannels ~/.julia/dev/Genie/src/WebChannels.jl:220
true
```

The error is caused by the fact that, by reloading the page, our previously connected WebSockets client is now unreachable. However, we still keep a reference to it - and when we try to broadcast to it, we find that the stream has been closed. We can fix this by calling

```julia
julia> Genie.WebChannels.unsubscribe_disconnected_clients()
```

The output of `unsubscribe_disconnected_clients()` is the collection of remaining (connected) clients.

---

** Heads up! **

Although harmless, the error indicates that you have disconnected clients in memory. If you don't need the data, purge them to free memory.

---

At any time, we can check the connected clients with `Genie.WebChannels.connected_clients()` and the disconnected ones with `Genie.WebChannels.disconnected_clients()`.

### Pushing messages from the client

We can also push messages from client to server. As we don't have a UI, we'll use the browser's console and Genie's JavaScript API to send the message. But first, we need to set up the `channel` which will receive our message. Run this in the active Julia REPL:

```julia
channel("/__/echo") do
  "Received: $(@params(:payload))"
end
```

Now that our endpoint is up, go to the browser's console and run:
```javascript
Genie.WebChannels.sendMessageTo('__', 'echo', 'Hello!')
```

The console will immediately display the response from the server:

```text
Received: Hello!  channels.js:74:3
Got this payload: Received: Hello!
```

## Summary

This concludes our intro to working with WebSockets in Genie. You know have the knowledge to set up the communication between client and server, send messages from both server and clients, and perform various tasks using the `WebChannels` API.
