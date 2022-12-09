@safetestset "DotEnv functionality" begin
  @safetestset "Create and run new Genie App" begin
    testdir = pwd()

    using Pkg
    using Genie

    tmpdir = Base.Filesystem.mktempdir()
    cd(tmpdir)

    @async Genie.Generator.newapp("testapp"; autostart=false, testmode=true)
    sleep(10)

    mv(".env.example", ".env")
    Genie.Loader.DotEnv.config()

    task = @async run(`bin/server`, wait=false)
    sleep(10)

    r = Genie.Requests.HTTP.request("GET", "http://$(ENV["HOST"]):$(ENV["PORT"])/")
    @test r.status == Genie.Router.OK

    try
      @async Base.throwto(task, InterruptException())
    catch
    end

    kill(task |> fetch)
    task = nothing

    cd(testdir)
    Pkg.activate(".")
  end

end