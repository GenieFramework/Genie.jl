

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Channels.subscribe' href='#Channels.subscribe'>#</a>
**`Channels.subscribe`** &mdash; *Function*.



```
subscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void
```

Subscribes a web socket client `ws` to `channel`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L22-L26' class='documenter-source'>source</a><br>

<a id='Channels.unsubscribe' href='#Channels.unsubscribe'>#</a>
**`Channels.unsubscribe`** &mdash; *Function*.



```
unsubscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void
```

Unsubscribes a web socket client `ws` from `channel`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L43-L47' class='documenter-source'>source</a><br>

<a id='Channels.unsubscribe_client' href='#Channels.unsubscribe_client'>#</a>
**`Channels.unsubscribe_client`** &mdash; *Function*.



```
unsubscribe_client(ws::WebSockets.WebSocket, channel::ChannelId) :: Void
```

Unsubscribes a web socket client `ws` from all the channels.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L59-L63' class='documenter-source'>source</a><br>

<a id='Channels.push_subscription' href='#Channels.push_subscription'>#</a>
**`Channels.push_subscription`** &mdash; *Function*.



```
push_subscription(client::ClientId, channel::ChannelId) :: Void
```

Adds a new subscription for `client` to `channel`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L75-L79' class='documenter-source'>source</a><br>

<a id='Channels.pop_subscription' href='#Channels.pop_subscription'>#</a>
**`Channels.pop_subscription`** &mdash; *Function*.



```
pop_subscription(client::ClientId, channel::ChannelId) :: Void
```

Removes the subscription of `client` to `channel`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L91-L95' class='documenter-source'>source</a><br>


```
pop_subscription(client::ClientId) :: Void
```

Removes all subscriptions of `client`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L105-L109' class='documenter-source'>source</a><br>

<a id='Channels.broadcast' href='#Channels.broadcast'>#</a>
**`Channels.broadcast`** &mdash; *Function*.



```
broadcast(channels::Vector{ChannelId}, msg::String) :: Void
```

Pushes `msg` to all the clients subscribed to the channels in `channels`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L119-L123' class='documenter-source'>source</a><br>


```
broadcast(msg::String) :: Void
```

Pushes `msg` to all the clients subscribed to all the channels.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Channels.jl#L140-L144' class='documenter-source'>source</a><br>

