@safetestset "Sort Load Order based on .autoload" begin
    using Genie

    order = Genie.Loader.sort_load_order("loader", readdir("loader"))
    @test order == ["xyz.jl", "-my-test-file.jl", "def.jl", "Abc.jl", ".autoload", "Aaa.jl", "Abb.jl"]

    @test get(ENV, "FOO", "") == ""
    Genie.Loader.load_dotenv()
    @test get(ENV, "FOO", "") == "bar"
    delete!(ENV, "FOO")
end

@safetestset "Loading of submodules via @using" begin
    # @test_logs (:info, "loading MyModule") include(joinpath(@__DIR__, "loader_using/include-mymodule-1.jl"))
    # somehow the above test doesn't capture the output, so we're just testing the success

    # loading from the Main module via `using`
    @test (include(joinpath(@__DIR__, "loader_using/using_from_main.jl")); true)
    # loading from a module with a relative path
    @test (include(joinpath(@__DIR__, "loader_using/using_from_submodule_relative.jl")); true)
    # loading from a module with a path relative to project directory
    @test (include(joinpath(@__DIR__, "loader_using/using_from_submodule_project.jl")); true)
end