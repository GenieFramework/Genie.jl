@safetestset "DotEnv functionality" begin

  @safetestset "ENV variables JSON endpoint check" begin
    # using Logging
    # Logging.global_logger(NullLogger())

    # testdir = pwd()

    # using Pkg
    # using Genie

    # tmpdir = Base.Filesystem.mktempdir()
    # cd(tmpdir)

    # @async Genie.Generator.newapp("testapp"; autostart=false, testmode=true)
    # sleep(10)

    # mv(".env.example", ".env")
    # Genie.Loader.DotEnv.config()

    # write("routes.jl", 
    # """
    # using Genie.Router
    # using Genie.Renderer.Json

    # route("/") do
    #   Dict("PORT" => ENV["PORT"],
    #    "WSPORT" => ENV["WSPORT"],
    #    "HOST" => ENV["HOST"]) |> json
    # end
    # """)

    # if Sys.iswindows()
    #   task = @async run(`bin\\server.bat`, wait=false)
    # else
    #   task = @async run(`bin/server`, wait=false)
    # end

    # sleep(10)

    # r = Genie.Requests.HTTP.request("GET", "http://$(ENV["HOST"]):$(ENV["PORT"])/")
    # @test r.status == Genie.Router.OK

    # eobj = Genie.Renderer.Json.JSONParser.parse(String(r.body))

    # @test eobj["PORT"] == ENV["PORT"]
    # @test eobj["WSPORT"] == ENV["WSPORT"]
    # @test eobj["HOST"] == ENV["HOST"]

    # try
    #   Genie.Util.killtask(task)
    # catch
    # end

    # kill(task |> fetch)
    # task = nothing

    # cd(testdir)
    # Pkg.activate(".")
  end
end