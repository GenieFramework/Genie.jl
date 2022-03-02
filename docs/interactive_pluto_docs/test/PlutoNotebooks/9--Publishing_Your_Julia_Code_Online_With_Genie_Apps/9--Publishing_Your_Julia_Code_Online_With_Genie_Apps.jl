### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ c10a143e-3226-11ec-06d1-13d8fedcc6e3
# hideall

using Genie;

# ╔═╡ e608c9a3-3875-48f3-b28c-991e05534072
md"""
# Adding your existing Julia code into Genie apps

If you have existing Julia code (modules and libraries) which you'd like to quickly expose on the web without building an app from scratch, Genie provides an easy way to add and load your code into an app.

## Adding your Julia code to a Genie app

If you have an existing Julia application or standalone codebase which you'd like to expose over the web through a Genie app, the simplest thing is to add the files to the `lib/` folder. The `lib/` folder is automatically added by Genie to the `LOAD_PATH`, _recursively_.

This means that you can also add folders under `lib/`, and they will be recursively added to the `LOAD_PATH`. Beware though that this only happens when the Genie app is initially loaded. Hence, an app restart might be required if you add nested folders after the app is started.
"""

# ╔═╡ 2589c03d-fd17-4ba3-bdf9-90c4d779a136
md"""
Creating a simple Genie web service:
"""

# ╔═╡ 03fce09f-0f05-47bd-960b-eed9ef1087dd
# hideall

Genie.newapp_webservice("MyGenieApp");

# ╔═╡ c7ca2f4a-09d4-48d3-bb96-1fea6195b9cf
md"""
**HEADS UP**

In most cases, Genie won't create the `lib/` folder by default. If the `lib/` folder is not present in the root of the app, just create it yourself:
"""

# ╔═╡ 47574366-5c9a-47be-ac60-6a93a4ab9d81
md"""

```julia
julia> mkdir("lib")
```
"""

# ╔═╡ 4f7496dd-fa87-4180-8d6e-dfe663d66cc4
# hideall 

begin
	incPath= true
	mkdir("lib")
end

# ╔═╡ b439eaa1-f4e9-40a5-9671-8684d5e7bd2c
# hideall

begin
	incPath;
	include("routes.jl");
end;

# ╔═╡ 31191d7b-45c9-434f-8be5-9f0088859ce5
# hideall

begin
	incPath
	@assert ispath("lib") == true
end

# ╔═╡ 22c1473d-c623-475b-9a18-41f5977c02c9
md"""
Once your code is added to the `lib/` folder, it will become available in your app's environment. For example, say we have a file called `lib/MyLib.jl`:

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

Then we can reference it in `routes.jl` and expose it on the web as follows:

"""

# ╔═╡ 07e003a6-297e-486a-b8dc-acd18cf15d0c
# hideall

begin
	incPath;
	touch("lib/MyLib.jl");
end;

# ╔═╡ c6427379-f6fb-4a3e-8be7-e3d1b9e3ad52
# hideall

begin
	incPath;
	@assert isfile("lib/MyLib.jl") == true;
end;

# ╔═╡ de394ad3-d9f3-44da-89e0-411d38c72deb
# hideall

begin
	incPath;
	write("lib/MyLib.jl", """
		# lib/MyLib.jl
	module MyLib

	using Dates

	function isitfriday()
	  Dates.dayofweek(Dates.now()) == Dates.Friday
	end

	end""");
end;

# ╔═╡ 8f6ffc7c-0102-4682-8779-ccba834982c9
md"""

```julia
# routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```
"""

# ╔═╡ 394e18be-97d6-4456-8f7c-3f5c13d47d12
# hideall

Genie.Router.routes();

# ╔═╡ d9a2ee12-f679-44c7-bd9b-0b83192e37a7
md"""
Use the `lib/` folder to host your Julia code so that Genie knows where to look in order to load it and make it available throughout the application.
"""

# ╔═╡ de8ba170-f425-4cbf-a21c-8eb926fbe683
# hideall

begin
	incPath;
	@assert isfile("routes.jl") == true;
end;

# ╔═╡ 0e49172c-a2e1-4499-a2bf-672daa13f9b9
md"""
Adding above code snippet to `routes.jl`
"""

# ╔═╡ dd5a7ecd-a950-478c-b458-4e138f41d89d
# hideall

write("routes.jl", """
	# routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end""");

# ╔═╡ be30e358-da0f-42d5-b984-d3e80fe16c65
# hideall
down();

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Genie = "c43c736e-a2d1-11e8-161f-af95117fbd1e"

[compat]
Genie = "~4.1.0"
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
git-tree-sha1 = "f9a6389348207faf5e5c62cbc7e89d19688d338a"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.3.0"

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
git-tree-sha1 = "618835ab81e4a40acf215c98768978d82abc5d97"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.16"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"

[[Genie]]
deps = ["ArgParse", "Dates", "Distributed", "EzXML", "FilePathsBase", "HTTP", "HttpCommon", "Inflector", "JSON3", "JuliaFormatter", "Logging", "Markdown", "MbedTLS", "Millboard", "Nettle", "OrderedCollections", "Pkg", "REPL", "Reexport", "Revise", "SHA", "Serialization", "Sockets", "UUIDs", "Unicode", "VersionCheck", "YAML"]
git-tree-sha1 = "1cb249c696d4c81d1dde38277602fbad6dc16594"
uuid = "c43c736e-a2d1-11e8-161f-af95117fbd1e"
version = "4.1.0"

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
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

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
# ╟─e608c9a3-3875-48f3-b28c-991e05534072
# ╠═c10a143e-3226-11ec-06d1-13d8fedcc6e3
# ╟─2589c03d-fd17-4ba3-bdf9-90c4d779a136
# ╠═03fce09f-0f05-47bd-960b-eed9ef1087dd
# ╟─c7ca2f4a-09d4-48d3-bb96-1fea6195b9cf
# ╟─47574366-5c9a-47be-ac60-6a93a4ab9d81
# ╠═4f7496dd-fa87-4180-8d6e-dfe663d66cc4
# ╠═31191d7b-45c9-434f-8be5-9f0088859ce5
# ╟─22c1473d-c623-475b-9a18-41f5977c02c9
# ╠═07e003a6-297e-486a-b8dc-acd18cf15d0c
# ╠═c6427379-f6fb-4a3e-8be7-e3d1b9e3ad52
# ╠═de394ad3-d9f3-44da-89e0-411d38c72deb
# ╟─8f6ffc7c-0102-4682-8779-ccba834982c9
# ╠═394e18be-97d6-4456-8f7c-3f5c13d47d12
# ╠═d9a2ee12-f679-44c7-bd9b-0b83192e37a7
# ╠═de8ba170-f425-4cbf-a21c-8eb926fbe683
# ╟─0e49172c-a2e1-4499-a2bf-672daa13f9b9
# ╠═dd5a7ecd-a950-478c-b458-4e138f41d89d
# ╠═b439eaa1-f4e9-40a5-9671-8684d5e7bd2c
# ╠═be30e358-da0f-42d5-b984-d3e80fe16c65
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
