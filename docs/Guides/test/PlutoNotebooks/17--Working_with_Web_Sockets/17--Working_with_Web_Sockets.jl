### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 332e4ec2-b1c5-47c0-a12e-db0195023e18
# hideall

using Genie, Genie.Router

# ╔═╡ 69bec8f4-56b1-48ee-aa2c-ba4310e79568
# hideall

using Genie.Assets;

# ╔═╡ 32df4cc8-39ac-11ec-2f5e-b176daa6db9a
md"""
# Working with Web Sockets

Genie provides a powerful workflow for client-server communication over websockets. The system hides away the complexity of the network level communication, exposing powerful abstractions which resemble Genie's familiar MVC workflow: the clients and the server exchange messages over `channels` (which are the equivalent of `routes`).

## Registering `channels`

The messages are mapped to a matching channel, where are processed by Genie's `Router` which extracts the payload and invokes the designated handler (controller method or function). For most purposes, the `channels` are the functional equivalents of `routes` and are defined in the same way:
"""

# ╔═╡ a54bd0a5-7ec6-46db-8d42-a4cfc3eb1c2f
md"""
If you are using Julia REPL and Pluto notebook. Execute the below lines: 

```julia
julia> import Pkg
julia> Pkg.add("Genie")
```
"""

# ╔═╡ c7ea1c3e-2a61-41d4-ba37-21027f56453a
md"""

```julia
julia> using Genie, Genie.Router

julia> channel("/foo/bar") do
         # process request
       end

```

"""

# ╔═╡ a8b81c5a-6a04-4ef6-8522-82582da4f78a
# hideall

channel("/foo/bar") do
	#process request
end

# ╔═╡ 72010195-6acc-4a4c-bb58-5331f8007192
md"""

```julia
julia> module YourController
        function your_handler
		   #process request
        end
       end
```
"""

# ╔═╡ dc4430bf-4555-4b3a-9c9c-9c14ef4ac806
# hideall

module YourController
	function your_handler
	 	#process request
	end
end

# ╔═╡ bd80dd1c-6e99-4c60-91d3-e470b9f5020c
md"""

```julia
julia> channel("/baz/bax", YourController.your_handler)
```
"""

# ╔═╡ a6ec9f7f-c574-4af0-a755-5d090a00d423
# hideall

channel("/baz/bax", YourController.your_handler)

# ╔═╡ b65c4644-f5f8-4a68-8df7-8064b1274ba5
md"""
The above `channel` definitions will handle websocket messages sent to `/foo/bar` and `/baz/bax`.
"""

# ╔═╡ f082d891-61ba-4a9f-b1ea-943ed2aba815
md"""
## Setting up the client

In order to enable WebSockets communication in the browser we need to load a JavaScript file. This is provided by Genie, through the `Assets` module. Genie makes it extremely easy to setup the WebSockets infrastructure on the client side, by providing the `Assets.channels_support()` method. For instance, if we want to add support for WebSockets to the root page of a web app, all we need is this:
"""

# ╔═╡ 3911bc31-f4ea-493e-95a9-9d743670c4c6
md"""

```julia
julia> using Genie, Genie.Router, Genie.Assets
```
"""

# ╔═╡ 266ce7f3-4364-44ec-90b8-61e06dba5d27
md"""

```julia
julia> route("/") do
		 Assets.channels_support()
	   end
```
"""

# ╔═╡ 70db282b-ec1c-40f7-bd7c-59ed2e94891c
# hideall

route("/") do
    Assets.channels_support()
end

# ╔═╡ 45c63333-2726-400e-a179-996ce88f456a
md"""
Literally, that is all we need in order to be able to push and receive messages between client and server.
"""

# ╔═╡ 15c148af-9708-4cec-a390-17a87a02a8fb
md"""
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
"""

# ╔═╡ 78550cf1-a2ef-487e-87a1-589fe3c7c048
# hideall

begin
	Genie.config.websockets_server = true; # enable the websockets server

	route("/") do
  		Assets.channels_support();
	end;
	
	up();
end;

# ╔═╡ 5350a2e0-2f95-4fb6-a9e5-18b4fc58d84f
md"""

to shutdown server

```julia
julia> down();
```
"""

# ╔═╡ 52576077-67bd-4a24-b81b-be6f475d4192
# hideall

down();

# ╔═╡ e8137d45-a1c8-480c-80b3-05454f3d241b
md"""
Now if you visit <http://localhost:8000> you'll get a blank page -- which, however, includes all the necessary functionality for WebSockets communication! If you use the browser's developer tools, the Network pane will indicate that a `channels.js` file was loaded and that a WebSockets request was made (Status 101 over GET). Additionally, if you peek at the Console, you will see a `Subscription ready` message. The output in the console should be something like:
"""

# ╔═╡ a26be9e1-42ce-43d6-8c36-d2a08ba75f99
md"""

```text
Subscription ready
channels.js:133 Overwrite window.parse_payload to handle messages from the server
channels.js:134 Subscription: OK
```
"""

# ╔═╡ 0f99c27a-29df-4aad-a387-12799664569f
md"""
**What happened?**

At this point, by invoking `Assets.channels_support()`, Genie has done the following:

* loaded the bundled `channels.js` file which provides a JS API for communicating over WebSockets
* has created two default channels, for subscribing and unsubscribing: `/__/subscribe` and `/__/unsubscribe`
* has invoked `/__/subscribe` and created a WebSockets connection between client and server

### Pushing messages from the server

We are ready to interact with the client. Go to the Julia REPL running the web app and run:
"""

# ╔═╡ fabc9669-ce12-470f-b551-3d8f69cb221b
md"""

```julia
julia> Genie.WebChannels.connected_clients()
1-element Array{Genie.WebChannels.ChannelClient,1}:
 Genie.WebChannels.ChannelClient(HTTP.WebSockets.WebSocket{HTTP.ConnectionPool.Transaction{Sockets.TCPSocket}}(T0  🔁    0↑🔒    0↓🔒 100s 127.0.0.1:8001:8001 ≣16, 0x01, true, UInt8[0x7b, 0x22, 0x63, 0x68, 0x61, 0x6e, 0x6e, 0x65, 0x6c, 0x22  …  0x79, 0x6c, 0x6f, 0x61, 0x64, 0x22, 0x3a, 0x7b, 0x7d, 0x7d], UInt8[], false, false), ["__"])
```
"""

# ╔═╡ 79660882-e6d9-4125-8601-277888c199a5
# hideall

Genie.WebChannels.connected_clients();

# ╔═╡ 229008fe-bad8-455b-853f-57eb39e87665
md"""
We have one connected client to the `__` channel! We can send it a message:
"""

# ╔═╡ b35f5984-9f46-4303-9f0a-af7c79cf7a53
md"""
```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
true
```
"""

# ╔═╡ 4b6f463c-7453-4f06-a51d-29cc42e66550
md"""
If you look in the browser's console you will see the "Hey!" message! By default, the client side handler simply outputs the message. We're also informed that we can "Overwrite window.parse_payload to handle messages from the server". Let's do it. Run this in the current REPL (it will overwrite our root route handler):
"""

# ╔═╡ 3085ac1c-ebf5-4199-b255-a7c10efafbd2
route("/") do
  Assets.channels_support() *
  """
  <script>
  window.parse_payload = function(payload) {
    console.log('Got this payload: ' + payload);
  }
  </script>
  """
end;

# ╔═╡ 0135778f-63a0-48e1-8e12-e3407d8d5c8b
md"""
Now if you reload the page and broadcast the message, it will be picked up by our custom payload handler. However, chances are you'll also get an error when broadcasting (don't worry though, the error is just logged, it's not breaking the application as it's not critical):
"""

# ╔═╡ e65f8790-8bbe-49ce-9678-23dfa714b6c4
md"""

```julia
julia> Genie.WebChannels.broadcast("__", "Hey!")
┌ Error: Base.IOError("stream is closed or unusable", 0)
└ @ Genie.WebChannels ~/.julia/dev/Genie/src/WebChannels.jl:220
true

```
"""

# ╔═╡ 3c9eb96d-a4e3-48a5-8d90-31c0dea9bd1f
md"""
The error is caused by the fact that, by reloading the page, our previously connected WebSockets client is now unreachable. However, we still keep a reference to it - and when we try to broadcast to it, we find that the stream has been closed. We can fix this by calling
"""

# ╔═╡ 1e16ffe0-f14a-42d9-b05b-ff899763679a
md"""
```julia
julia> Genie.WebChannels.unsubscribe_disconnected_clients()
```
"""

# ╔═╡ 6fa1c839-4dd4-421b-992f-13827883cea6
md"""
The output of `unsubscribe_disconnected_clients()` is the collection of remaining (connected) clients.
"""

# ╔═╡ 3e6e402d-601c-45ea-acad-44cb9ed5219d
md"""
---

**Heads up!**

Although harmless, the error indicates that you have disconnected clients in memory. If you don't need the data, purge them to free memory.

---

At any time, we can check the connected clients with `Genie.WebChannels.connected_clients()` and the disconnected ones with `Genie.WebChannels.disconnected_clients()`.

### Pushing messages from the client

We can also push messages from client to server. As we don't have a UI, we'll use the browser's console and Genie's JavaScript API to send the message. But first, we need to set up the `channel` which will receive our message. Run this in the active Julia REPL:
"""

# ╔═╡ 989907fb-8179-4029-92a4-e0ee44e52ccb
channel("/__/echo") do
  "Received: $(params(:payload))"
end;

# ╔═╡ bf14645c-3fbe-4531-983a-998cc5d629ea
md"""
Now that our endpoint is up, go to the browser's console and run:
```javascript
Genie.WebChannels.sendMessageTo('__', 'echo', 'Hello!')
```
"""

# ╔═╡ f57df6f7-e612-47d8-8856-c2b0eddde564
md"""
The console will immediately display the response from the server:

```text
Received: Hello!  channels.js:74:3
Got this payload: Received: Hello!
```
"""

# ╔═╡ 4e8d5270-116d-4f1c-b410-95724c97d359
md"""
## Summary

This concludes our intro to working with WebSockets in Genie. You now have the knowledge to set up the communication between client and server, send messages from both server and clients, and perform various tasks using the `WebChannels` API.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"

[compat]
Genie = "~3.3.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ArgParse]]
deps = ["Logging", "TextWrap"]
git-tree-sha1 = "3102bce13da501c9104df33549f511cd25264d7d"
uuid = "c7e460c6-2fb9-53a9-8c5b-16f535851c63"
version = "1.1.4"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[CSTParser]]
deps = ["Tokenize"]
git-tree-sha1 = "b2667530e42347b10c10ba6623cfebc09ac5c7b6"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.2.4"

[[CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[CommonMark]]
deps = ["Crayons", "JSON", "URIs"]
git-tree-sha1 = "393ac9df4eb085c2ab12005fc496dae2e1da344e"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.3"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dce3e3fea680869eaa0b774b2e8343e9ff442313"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.40.0"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[FilePathsBase]]
deps = ["Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "d962b5a47b6d191dbcd8ae0db841bc70a05a3f5b"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.13"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"

[[Genie]]
deps = ["ArgParse", "Dates", "Distributed", "EzXML", "FilePathsBase", "HTTP", "HttpCommon", "Inflector", "JSON3", "JuliaFormatter", "Logging", "Markdown", "MbedTLS", "Millboard", "Nettle", "OrderedCollections", "Pkg", "REPL", "Reexport", "Revise", "SHA", "Serialization", "Sockets", "UUIDs", "Unicode", "YAML"]
git-tree-sha1 = "4f5526913b239ece648a73d4445c7978f1251935"
uuid = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
version = "3.3.0"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "14eece7a3308b4d8be910e265c724a6ba51a9798"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.16"

[[HttpCommon]]
deps = ["Dates", "Nullables", "Test", "URIParser"]
git-tree-sha1 = "46313284237aa6ca67a6bce6d6fbd323d19cff59"
uuid = "77172c1b-203f-54ac-aa54-3f1198fe9f90"
version = "0.5.0"

[[Inflector]]
deps = ["Unicode"]
git-tree-sha1 = "8555b54ddf27806b070ce1d1cf623e1feb13750c"
uuid = "6d011eab-0732-4556-8808-e463c76bf3b6"
version = "1.0.1"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JSON3]]
deps = ["Dates", "Mmap", "Parsers", "StructTypes", "UUIDs"]
git-tree-sha1 = "7d58534ffb62cd947950b3aa9b993e63307a6125"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.9.2"

[[JuliaFormatter]]
deps = ["CSTParser", "CommonMark", "DataStructures", "Pkg", "Tokenize"]
git-tree-sha1 = "10c95cebcfa37c1f510a726c90886db4745e1238"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "0.15.11"

[[JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "e273807f38074f033d94207a201e6e827d8417db"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.8.21"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "491a883c4fef1103077a7f648961adbf9c8dd933"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.1.2"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Millboard]]
git-tree-sha1 = "ea6a5b7e56e76d8051023faaa11d91d1d881dac3"
uuid = "39ec1447-df44-5f4c-beaa-866f30b4d3b2"
version = "0.2.5"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[Nettle]]
deps = ["Libdl", "Nettle_jll"]
git-tree-sha1 = "a68340b9edfd98d0ed96aee8137cb716ea3b6dea"
uuid = "49dea1ee-f6fa-5aa6-9a11-8816cee7d4b9"
version = "0.5.1"

[[Nettle_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "eca63e3847dad608cfa6a3329b95ef674c7160b4"
uuid = "4c82536e-c426-54e4-b420-14f461c4ed8b"
version = "3.7.2+0"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Nullables]]
git-tree-sha1 = "8f87854cc8f3685a60689d8edecaa29d2251979b"
uuid = "4d1e1d77-625e-5b40-9113-a560ec7a8ecd"
version = "1.0.0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "d911b6a12ba974dabe2291c6d450094a7226b372"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.1"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "41deb3df28ecf75307b6e492a738821b031f8425"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.1.20"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StringEncodings]]
deps = ["Libiconv_jll"]
git-tree-sha1 = "50ccd5ddb00d19392577902f0079267a72c5ab04"
uuid = "69024149-9ee7-55f6-a4c4-859efe599b68"
version = "0.3.5"

[[StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "d24a825a95a6d98c385001212dc9020d609f2d4f"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.8.1"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TextWrap]]
git-tree-sha1 = "9250ef9b01b66667380cf3275b3f7488d0e25faf"
uuid = "b718987f-49a8-5099-9789-dcd902bef87d"
version = "1.0.1"

[[Tokenize]]
git-tree-sha1 = "0952c9cee34988092d73a5708780b3917166a0dd"
uuid = "0796e94c-ce3b-5d07-9a54-7f471281c624"
version = "0.5.21"

[[URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[YAML]]
deps = ["Base64", "Dates", "Printf", "StringEncodings"]
git-tree-sha1 = "3c6e8b9f5cdaaa21340f841653942e1a6b6561e5"
uuid = "ddb6d928-2868-570f-bddf-ab3f9cf99eb6"
version = "0.4.7"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─32df4cc8-39ac-11ec-2f5e-b176daa6db9a
# ╟─a54bd0a5-7ec6-46db-8d42-a4cfc3eb1c2f
# ╟─c7ea1c3e-2a61-41d4-ba37-21027f56453a
# ╠═332e4ec2-b1c5-47c0-a12e-db0195023e18
# ╠═a8b81c5a-6a04-4ef6-8522-82582da4f78a
# ╟─72010195-6acc-4a4c-bb58-5331f8007192
# ╟─dc4430bf-4555-4b3a-9c9c-9c14ef4ac806
# ╟─bd80dd1c-6e99-4c60-91d3-e470b9f5020c
# ╠═a6ec9f7f-c574-4af0-a755-5d090a00d423
# ╟─b65c4644-f5f8-4a68-8df7-8064b1274ba5
# ╟─f082d891-61ba-4a9f-b1ea-943ed2aba815
# ╟─3911bc31-f4ea-493e-95a9-9d743670c4c6
# ╠═69bec8f4-56b1-48ee-aa2c-ba4310e79568
# ╟─266ce7f3-4364-44ec-90b8-61e06dba5d27
# ╠═70db282b-ec1c-40f7-bd7c-59ed2e94891c
# ╟─45c63333-2726-400e-a179-996ce88f456a
# ╟─15c148af-9708-4cec-a390-17a87a02a8fb
# ╠═78550cf1-a2ef-487e-87a1-589fe3c7c048
# ╟─5350a2e0-2f95-4fb6-a9e5-18b4fc58d84f
# ╠═52576077-67bd-4a24-b81b-be6f475d4192
# ╟─e8137d45-a1c8-480c-80b3-05454f3d241b
# ╟─a26be9e1-42ce-43d6-8c36-d2a08ba75f99
# ╟─0f99c27a-29df-4aad-a387-12799664569f
# ╟─fabc9669-ce12-470f-b551-3d8f69cb221b
# ╠═79660882-e6d9-4125-8601-277888c199a5
# ╟─229008fe-bad8-455b-853f-57eb39e87665
# ╟─b35f5984-9f46-4303-9f0a-af7c79cf7a53
# ╟─4b6f463c-7453-4f06-a51d-29cc42e66550
# ╠═3085ac1c-ebf5-4199-b255-a7c10efafbd2
# ╟─0135778f-63a0-48e1-8e12-e3407d8d5c8b
# ╟─e65f8790-8bbe-49ce-9678-23dfa714b6c4
# ╟─3c9eb96d-a4e3-48a5-8d90-31c0dea9bd1f
# ╟─1e16ffe0-f14a-42d9-b05b-ff899763679a
# ╟─6fa1c839-4dd4-421b-992f-13827883cea6
# ╟─3e6e402d-601c-45ea-acad-44cb9ed5219d
# ╠═989907fb-8179-4029-92a4-e0ee44e52ccb
# ╟─bf14645c-3fbe-4531-983a-998cc5d629ea
# ╟─f57df6f7-e612-47d8-8856-c2b0eddde564
# ╟─4e8d5270-116d-4f1c-b410-95724c97d359
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
