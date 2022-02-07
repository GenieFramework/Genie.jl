# Testing notebooks 

```shell
$ cd test
test$ julia --project

julia> ]
pkg> activate .
pkg> instantiate
```

In `docbuilder.jl` run only one runtest_*.jl at a time. Comment others i.e.

```julia

include("cleanup.jl")

include("runtest_guide.jl")

#include("runtest_tutorial_breaking.jl")

#include("runtest_tutorial.jl")
```

If everything goes well test should pass and produce `.html` files in `../build/genie*tutorials`

```shell
julia> include("docbuilder.jl")
```

Test files:
* runtest_guides
* runtest_tutorial
* runtest_tutorial (breaking tests run them separately after)

Passing test should look like this

```shell
Test Summary:     | Pass  Total
Genie Docs Test   |  531    531
     Testing runtest_guides tests passed
```