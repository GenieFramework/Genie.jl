@safetestset "DotEnv functionality" begin
  @safetestset "Create newapp and test ENV vars" begin
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

  @safetestset "ENV variables JSON endpoint" begin
    testdir = pwd()

    using Pkg
    using Genie

    tmpdir = Base.Filesystem.mktempdir()
    cd(tmpdir)

    @async Genie.Generator.newapp("testapp"; autostart=false, testmode=true)
    sleep(10)

    mv(".env.example", ".env")
    Genie.Loader.DotEnv.config()

    write("routes.jl", 
    """
    using Genie.Router
    using Genie.Renderer.Json

    route("/") do
      Dict("PORT" => ENV["PORT"],
       "WSPORT" => ENV["WSPORT"],
       "HOST" => ENV["HOST"]) |> json
    end
    """)

    task = @async run(`bin/server`, wait=false)
    sleep(10)

    r = Genie.Requests.HTTP.request("GET", "http://$(ENV["HOST"]):$(ENV["PORT"])/")

    eobj = Genie.Renderer.Json.JSONParser.parse(String(r.body))

    @test eobj["PORT"] == ENV["PORT"]
    @test eobj["WSPORT"] == ENV["WSPORT"]
    @test eobj["HOST"] == ENV["HOST"]

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