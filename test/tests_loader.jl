@safetestset "Sort Load Order based on .autoload" begin
    using Genie

    order = Genie.Loader.sort_load_order("loader", readdir("loader"))
    @test order == ["b.jl", "a.jl", ".autoload", "c.jl", "d.jl"]
end