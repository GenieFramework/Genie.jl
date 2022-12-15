@safetestset "Sort Load Order based on .autoload" begin
    using Genie

    order = Genie.Loader.sort_load_order("loader", readdir("loader"))
    @test order == ["xyz.jl", "-my-test-file.jl", "def.jl", "Abc.jl", ".autoload", "Aaa.jl", "Abb.jl"]
end