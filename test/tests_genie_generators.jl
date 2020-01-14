@testset "Create new app" begin

  testdir = pwd()
  using Pkg

  @safetestset "Do not autostart app" begin
    using Genie

    workdir = Base.Filesystem.mktempdir()

    Genie.newapp(workdir, autostart = false, testmode = true)

    @test true === true
  end;

  cd(testdir)
  Pkg.activate(".")

  @safetestset "Autostart app" begin
    using Genie

    workdir = Base.Filesystem.mktempdir()

    Genie.newapp(workdir, autostart = true, testmode = true)

    @test true === true
  end;

  cd(testdir)
  Pkg.activate(".")

  @safetestset "Microstack file structure" begin
    using Genie

    workdir = Base.Filesystem.mktempdir()

    Genie.newapp(workdir, autostart = false, testmode = true)

    @test readdir(workdir) == [ ".gitattributes", ".gitignore", "Manifest.toml", "Project.toml", "bin",
                                "bootstrap.jl", "config", "genie.jl", "public", "routes.jl", "src"]
    @test readdir(joinpath(workdir, Genie.config.path_initializers)) == ["converters.jl", "logging.jl"]

    # TODO: add test for files in /src /config /public and /bin
  end;

  cd(testdir)
  Pkg.activate(".")

  @safetestset "DB support file structure" begin
    using Genie

    workdir = Base.Filesystem.mktempdir()

    Genie.newapp(workdir, autostart = false, dbsupport = true, testmode = true)

    @test readdir(workdir) == [ ".gitattributes", ".gitignore", "Manifest.toml", "Project.toml", "bin",
                                "bootstrap.jl", "config", "db", "genie.jl", "public", "routes.jl", "src"]
    @test readdir(joinpath(workdir, Genie.config.path_db)) == ["connection.yml", "migrations", "seeds"]
    @test readdir(joinpath(workdir, Genie.config.path_initializers)) == ["converters.jl", "logging.jl", "searchlight.jl"]
  end;
end;