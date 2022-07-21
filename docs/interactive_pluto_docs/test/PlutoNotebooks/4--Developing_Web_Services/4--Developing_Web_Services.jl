### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 581b00ef-e590-4b33-910c-f4f9525a9626
# hideall

using Genie

# ╔═╡ f3799f4a-4926-11ec-2bf8-a5ce535d651e
md"""
# Developing Genie Web Services

Starting up ad-hoc web servers at the REPL and writing small scripts to wrap micro-services works great, but production apps tend to become complex very quickly. They also have more stringent requirements, like managing dependencies, compressing assets, reloading code, logging, environments, or structuring the codebase in a way which promotes efficient workflows when working in teams.

Genie apps provide all these features, from dependency management and versioning (using Julia's `Pkg`, since a Genie app is a Julia project), to a powerful asset pipeline (using industry vetted tools like Yarn and Webpack), automatic code reloading in development (provided by `Revise.jl`), and a clear resource-oriented MVC layout.

Genie enables a modular approach towards app building, allowing to add more components as the need arises. You can start with the web service template (which includes dependencies management, logging, environments, and routing), and grow it by sequentially adding DB persistence  (through the SearchLight ORM), high performance HTML view templates with embedded Julia (via Flax), asset pipeline and compilation, and more.

## Setting up a Genie Web Service project

Genie packs handy generator features and templates which help bootstrapping and setting up various parts of an application. For bootstrapping a new app we need to invoke one of the functions in the `newapp` family:
"""

# ╔═╡ f1e11f9d-a5ce-4d6b-9e26-ce39800cac20
md"""

#### Adding Genie package

```julia
julia> using Pkg

julia> Pkg.add("Genie")
```

##### Importing Genie

```julia
julia> using Genie

julia> Genie.Generator.newapp_webservice("MyGenieApp")
```

"""

# ╔═╡ 4226f596-ce42-4953-966f-ea1afe32b698
# hideall

Genie.Generator.newapp_webservice("MyGenieApp")

# ╔═╡ 2ebe66be-24b5-4765-8a58-0ccac149799b
md"""
If you follow the log messages in the REPL you will see that the command will trigger a flurry of actions in order to set up the new project:

- it creates a new folder, `MyGenieApp/`, which will hosts the files of the app and whose name corresponds to the name of the app,
- within the `MyGenieApp/` folder, it creates the files and folders needed by the app,
- changes the active directory to `MyGenieApp/` and creates a new Julia project within it (adding the `Project.toml` file),
- installs all the required dependencies for the new Genie app (using `Pkg` and the standard `Manifest.toml` file), and finally,
- starts the web server

---
**TIP**

Check out the inline help for `Genie.Generator.newapp`, `Genie.Generator.newapp_webservice`, `Genie.Generator.newapp_mvc`, and `Genie.Generator.newapp_fullstack` too see what options are available for bootstrapping applications. We'll go over the different configurations in upcoming sections.

---

## The file structure

Our newly created web service has this file structure:

```julia
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── genie.jl
├── log
├── public
├── routes.jl
└── src
```

These are the roles of each of the files and folders:

- `Manifest.toml` and `Project.toml` are used by Julia and `Pkg` to manage the app's dependencies.
- `bin/` includes scripts for starting up a Genie REPL or a Genie server.
- `bootstrap.jl`, `genie.jl`, as well as all the files within `src/` are used by Genie to load the application and _should not be user modified_.
- `config/` includes the per-environment configuration files.
- `log/` is used by Genie to store per-environment log files.
- `public/` is the document root, which includes static files exposed by the app on the network/internet.
- `routes.jl` is the dedicated file for registering Genie routes.

---
**HEADS UP**

After creating a new app you might need to change the file permissions to allow editing/saving the files such as `routes.jl`.

---

## Adding logic

You can now edit the `routes.jl` file to add some logic, at the bottom of the file:"""

# ╔═╡ 8b7366bc-beca-428e-8e03-ae02e5000e8f
md"""
```julia
route("/hello") do
  "Welcome to Genie!"
end
```
"""

# ╔═╡ 685dec36-b77a-470f-aa59-0e460aaf1188
md"""
If you now visit <http://127.0.0.1:8000/hello> you'll see a warm greeting.
"""

# ╔═╡ 76c662cc-74f9-4f55-9c55-9fdd14febc88
md"""
## Growing the app

Genie apps are just plain Julia projects. This means that `routes.jl` will behave like any other Julia script - you can reference extra packages, you can switch into `pkg>` mode to manage per project dependencies, include other files, etcetera.

If you have existing Julia code that you want to quickly load into a Genie app, you can add a `lib/` folder in the root of the app and place your Julia files there. When available, `lib/` and all its subfolders are automatically added to the `LOAD_PATH` by Genie, recursively.

If you need to add database support, you can always add the SearchLight ORM by using the dedicated generator, running `julia> Genie.Generator.db_support()` in the app's REPL.

However, if your app grows in complexity and you develop it from scratch, it is more efficient to take advantage of Genie's resource-oriented MVC structure.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"

[compat]
Genie = "~4.12.0"
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
git-tree-sha1 = "6cc1759204bed5a4e2a5c2f00901fd5d90bc7a62"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.3.1"

[[CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[CommonMark]]
deps = ["Crayons", "JSON", "URIs"]
git-tree-sha1 = "4cd7063c9bdebdbd55ede1af70f3c2f48fab4215"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.6"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

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
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "04d13bfa8ef11720c24e4d840c0033d145537df7"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.17"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"

[[Genie]]
deps = ["ArgParse", "Dates", "Distributed", "EzXML", "FilePathsBase", "HTTP", "HttpCommon", "Inflector", "JSON3", "JuliaFormatter", "Logging", "Markdown", "MbedTLS", "Millboard", "Nettle", "OrderedCollections", "Pkg", "REPL", "Random", "Reexport", "Revise", "SHA", "Serialization", "Sockets", "UUIDs", "Unicode", "VersionCheck", "YAML"]
git-tree-sha1 = "226ea9a883fc5d2112344fa3ac6c28ee335d2cd3"
uuid = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
version = "4.12.0"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

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
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[JSON3]]
deps = ["Dates", "Mmap", "Parsers", "StructTypes", "UUIDs"]
git-tree-sha1 = "7d58534ffb62cd947950b3aa9b993e63307a6125"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.9.2"

[[JuliaFormatter]]
deps = ["CSTParser", "CommonMark", "DataStructures", "Pkg", "Tokenize"]
git-tree-sha1 = "fcfaddc61f766211b2c835d3eceaf999b6ea9555"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "0.22.4"

[[JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "b55aae9a2bf436fc797d9c253a900913e0e90178"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.3"

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
git-tree-sha1 = "6b0440822974cab904c8b14d79743565140567f6"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.1"

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
git-tree-sha1 = "13468f237353112a01b2d6b32f3d0f80219944aa"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.2"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

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
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "2f9d4d6679b5f0394c52731db3794166f49d5131"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.3.1"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

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

[[UrlDownload]]
deps = ["HTTP", "ProgressMeter"]
git-tree-sha1 = "05f86730c7a53c9da603bd506a4fc9ad0851171c"
uuid = "856ac37a-3032-4c1c-9122-f86d88358c8b"
version = "1.0.0"

[[VersionCheck]]
deps = ["Dates", "JSON3", "Logging", "Pkg", "Random", "Scratch", "UrlDownload"]
git-tree-sha1 = "89ef2431dd59344ebaf052d0737205854ded0c62"
uuid = "a637dc6b-bca1-447e-a4fa-35264c9d0580"
version = "0.2.0"

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
# ╟─f3799f4a-4926-11ec-2bf8-a5ce535d651e
# ╟─f1e11f9d-a5ce-4d6b-9e26-ce39800cac20
# ╠═581b00ef-e590-4b33-910c-f4f9525a9626
# ╠═4226f596-ce42-4953-966f-ea1afe32b698
# ╟─2ebe66be-24b5-4765-8a58-0ccac149799b
# ╟─8b7366bc-beca-428e-8e03-ae02e5000e8f
# ╟─685dec36-b77a-470f-aa59-0e460aaf1188
# ╟─76c662cc-74f9-4f55-9c55-9fdd14febc88
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
