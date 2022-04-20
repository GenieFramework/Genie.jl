### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ b07425d2-4bf7-47ce-b506-79abdc8a46d7
# hideall

using Genie

# ╔═╡ d98afa79-99c4-44cd-a47f-3f93cef703ff
# hideall

using Genie.Deploy

# ╔═╡ 5d2fc438-399f-11ec-26b4-cf583084b9d0
md"""
# Using Genie with Docker

Genie comes with built-in support for containerizing apps. The functionality is available in the `Genie.Deploy.Docker` module.

## Generating the Genie-optimised `Dockerfile`

You can bootstrap the Docker setup by invoking the `Genie.Deploy.Docker.dockerfile()` function. This will generate a custom `Dockerfile` optimized for Genie web apps containerization. The file will be generated in the current work dir (or where instructed by the optional argument `path` -- see the help for the `dockerfile()` function). Once generated, you can edit it and customize it as needed - Genie will not overwrite the file, thus preserving any changes.

The behaviour of `dockerfile()` can be controlled by passing any of the multiple optional arguments supported.

## Building the Docker container

Once we have our `Dockerfile` ready, we can invoke `Genie.Deploy.Docker.build()` in order to build the Docker container. You can optionally pass the container's name (by default `"genie"`) and the path (defaults to current work dir).

## Running the Genie app within the Docker container

When the image is ready, we can run it with `Genie.Deploy.Docker.run()`. We can configure any of the optional arguments in order to control how the app is run. Check the inline help for the function for more details.

## Examples

First let's create a Genie app:
"""

# ╔═╡ 3586dc6c-c9fa-42af-88b6-bd710bac1929
md"""
```julia
julia> using Genie
```
"""

# ╔═╡ 72531cdc-8652-4a42-8d10-7430e6c0595d
md"""
```julia
julia> Genie.newapp("DockerTest")
[ Info: Done! New app created at /Users/adrian/DockerTest
# output truncated
```
"""

# ╔═╡ 10aba7e4-3382-4119-acdb-54a53567c738
md"""
When it's ready, let's add the `Dockerfile`:
"""

# ╔═╡ b2125ab4-7aa9-458e-9f8a-155abdc3980e
md"""

```julia
julia> using Genie.Deploy

julia> Deploy.Docker.dockerfile()
Docker file successfully written at /Users/adrian/DockerTest/Dockerfile
```
"""

# ╔═╡ a2246c96-125e-4fa9-bf64-4e06cbacb5be
md"""

Now, to build our container:

```julia
julia> Deploy.Docker.build()
Sending build context to Docker daemon  1.056MB
Step 1/18 : FROM julia:latest
 ---> f4c9686d85da
# output truncated
Successfully tagged genie:latest
Docker container successfully built
```
"""

# ╔═╡ 5debfe7a-14aa-4471-b71f-782990e1f2aa
md"""
And finally, we can now run our app within the Docker container:
"""

# ╔═╡ ce13326f-d033-427b-803a-ee8a962bb6ac
md"""
```julia
julia> Deploy.Docker.run()
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp genie bin/server`

 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

| Web: https://genieframework.com
| GitHub: https://github.com/genieframework/Genie.jl
| Docs: https://genieframework.github.io/Genie.jl
| Gitter: https://gitter.im/essenciary/Genie.jl
| Twitter: https://twitter.com/GenieMVC

Genie v0.19.0
Active env: DEV

Web Server starting at http://127.0.0.1:8000

```
"""

# ╔═╡ 51c8088c-e388-4d2e-b20d-054d61cbe452
md"""
Our application starts inside the Docker container, binding port 8000 within the container (where the Genie app is running) to the port 80 of the host. So we are now able to access our app at `http://localhost`. If you navigate to `http://localhost` with your favourite browser you'll see Genie's welcome page. Notice that we don't access on port 8000 - this page is served from the Docker container on the default port 80.

### Using Docker during development

If we want to use Docker to serve the app during development, we need to _mount_ our app from host (your computer) into the container -- so that we can keep editing our files locally, but see the changes reflected in the Docker container. In order to do this we need to pass the `mountapp = true` argument to `Deploy.Docker.run()`, like this:
"""

# ╔═╡ 26b5630e-31a7-49ac-84d8-7c38b53d7dbf
md"""
```julia
julia> Deploy.Docker.run(mountapp = true)
Starting docker container with `docker run -it --rm -p 80:8000 --name genieapp -v /Users/adrian/DockerTest:/home/genie/app genie bin/server`
```
"""

# ╔═╡ 12d1e835-ba4c-4355-8575-509d86758cfd
md"""
When the app finishes starting, we can edit the files on the host using our favourite IDE, and see the changes reflected in the Docker container.
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
# ╟─5d2fc438-399f-11ec-26b4-cf583084b9d0
# ╠═3586dc6c-c9fa-42af-88b6-bd710bac1929
# ╠═b07425d2-4bf7-47ce-b506-79abdc8a46d7
# ╟─72531cdc-8652-4a42-8d10-7430e6c0595d
# ╟─10aba7e4-3382-4119-acdb-54a53567c738
# ╟─b2125ab4-7aa9-458e-9f8a-155abdc3980e
# ╠═d98afa79-99c4-44cd-a47f-3f93cef703ff
# ╟─a2246c96-125e-4fa9-bf64-4e06cbacb5be
# ╟─5debfe7a-14aa-4471-b71f-782990e1f2aa
# ╟─ce13326f-d033-427b-803a-ee8a962bb6ac
# ╟─51c8088c-e388-4d2e-b20d-054d61cbe452
# ╟─26b5630e-31a7-49ac-84d8-7c38b53d7dbf
# ╟─12d1e835-ba4c-4355-8575-509d86758cfd
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
