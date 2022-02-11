@safetestset "Fullstack app" begin

  @safetestset "Create and run a full stack app with resources" begin
    using Logging
    Logging.global_logger(NullLogger())

    testdir = pwd()
    using Pkg

    using Genie

    content = "Test OK!"

    workdir = Base.Filesystem.mktempdir()
    cd(workdir)

    Genie.newapp("fullstack_test", fullstack = true, testmode = true, interactive = false, autostart = false)

    Genie.Generator.newcontroller("Foo", pluralize = false)
    @test isfile(joinpath("app", "resources", "foo", "FooController.jl")) == true

    mkpath(joinpath("app", "resources", "foo", "views"))
    @test isdir(joinpath("app", "resources", "foo", "views")) == true

    open(joinpath("app", "resources", "foo", "views", "foo.jl.html"), "w") do io
      write(io, content)
    end
    @test isfile(joinpath("app", "resources", "foo", "views", "foo.jl.html")) == true

    Genie.Router.route("/test") do
      Genie.Renderer.Html.html(:foo, :foo)
    end

    up()
    sleep(5)

    r = Genie.Requests.HTTP.request("GET", "http://localhost:8000/test")

    @test occursin(content, String(r.body)) == true

    down()
    sleep(1)

    cd(testdir)
    Pkg.activate(".")
  end;

end;