# julia --project=test test/runtests.jl tests_autoloader
@safetestset "Autoload Basic Functionality" begin
  using Genie, Genie.Loader

  loader_path = joinpath(@__DIR__, "loader")
  lsdir = readdir(loader_path)
  sorted_files = Genie.Loader.sort_load_order(loader_path, lsdir)

  @test "xyz.jl" in sorted_files
  @test "-my-test-file.jl" in sorted_files
  @test "def.jl" in sorted_files
  @test "Abc.jl" in sorted_files

  @test !("-my-testfile.jl" in sorted_files)
  @test !("Foo.jl" in sorted_files)

  # Check specific order for some files
  xyz_idx = findfirst(x -> x == "xyz.jl", sorted_files)
  my_test_idx = findfirst(x -> x == "-my-test-file.jl", sorted_files)
  def_idx = findfirst(x -> x == "def.jl", sorted_files)
  abc_idx = findfirst(x -> x == "Abc.jl", sorted_files)

  @test xyz_idx < my_test_idx < def_idx < abc_idx
end

@safetestset "Autoload Recursive Persistent" begin
    using Genie, Genie.Loader

    Core.eval(Main, :(LOAD_ORDER = String[]))

    try
        lib_dir = joinpath(@__DIR__, "loader_recursive")
        Genie.Loader.autoload(lib_dir, context=Main)

        @test Main.LOAD_ORDER == ["Z", "C", "D", "B", "A"]
    finally
        Core.eval(Main, :(LOAD_ORDER = String[]))
    end
end



@safetestset "Autoload Missing File Tolerance" begin
    using Genie, Genie.Loader

    Core.eval(Main, :(LOAD_ORDER = String[]))

    test_dir = mktempdir()
    try
        write(joinpath(test_dir, "Real.jl"), "push!(Main.LOAD_ORDER, \"Real\")")
        write(joinpath(test_dir, ".autoload"), "Missing.jl\nReal.jl")

        Genie.Loader.autoload(test_dir, context=Main)

        @test Main.LOAD_ORDER == ["Real"]
    finally
        rm(test_dir, recursive=true)
        Core.eval(Main, :(LOAD_ORDER = String[]))
    end
end

@safetestset "Autoload Ignore Directive" begin
    using Genie, Genie.Loader

    Core.eval(Main, :(LOAD_ORDER = String[]))

    test_dir = mktempdir()
    try
        write(joinpath(test_dir, "Allowed.jl"), "push!(Main.LOAD_ORDER, \"Allowed\")")
        write(joinpath(test_dir, "Ignored.jl"), "push!(Main.LOAD_ORDER, \"Ignored\")")
        write(joinpath(test_dir, ".autoload"), "Allowed.jl\n-Ignored.jl")

        Genie.Loader.autoload(test_dir, context=Main)

        @test Main.LOAD_ORDER == ["Allowed"]
    finally
        rm(test_dir, recursive=true)
        Core.eval(Main, :(LOAD_ORDER = String[]))
    end
end

@safetestset "Autoload Custom Context" begin
    using Genie, Genie.Loader

    test_dir = mktempdir()
    target = Module(:AutoloadTest)
    try
        write(joinpath(test_dir, "Payload.jl"), "const AUTO_MESSAGE = \"loaded\"")
        write(joinpath(test_dir, ".autoload"), "Payload.jl")

        Genie.Loader.autoload(test_dir, context=target)

        @test invokelatest(() -> getproperty(target, :AUTO_MESSAGE)) == "loaded"
        @test !isdefined(Main, :AUTO_MESSAGE)
    finally
        rm(test_dir, recursive=true)
    end
end


