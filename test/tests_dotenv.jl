@safetestset "DotEnv functionality" begin
  @safetestset "Create and run new Genie App" begin
    # using Logging
    # Logging.global_logger(NullLogger())

    testdir = pwd()
    using Pkg
    using Genie

    workdir = Base.Filesystem.mktempdir()
    cd(workdir)
    
    Genie.Generator.newapp("testapp"; autostart = false)
    mv(".env.example", ".env")
    # @info readdir()
    # Pkg.activate(".")
    # Pkg.develop("Genie")
    # @info Pkg.status()
    Genie.loadapp()  

    @test ENV["PORT"] == 9001
    up()
    sleep(10)

    r = Genie.Requests.HTTP.request("GET", """http://localhost:$(ENV["PORT"])/""")
    @test r.status = Genie.Router.OK

    down()
    sleep(1)

    cd(testdir)
    Pkg.activate(".")
  end;
  
end;