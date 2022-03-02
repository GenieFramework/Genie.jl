# Testing notebooks 

```shell
$ cd test
test$ julia --project

julia> ]
pkg> activate .
pkg> instantiate
julia> include("runner.jl")
```

Passing test should look like this

```shell
Test Summary:     | Pass  Total
Genie Docs Test   |  531    531
     Testing runtest_guides tests passed
```
