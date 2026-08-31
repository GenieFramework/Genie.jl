#=

@testitem "Create new app" setup=[GenieTestSetup] begin

  testdir = pwd()
  using Pkg


  @testitem "Do not autostart app" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.Generator.newapp(workdir, autostart = false, testmode = true)

    @test true === true
  end;


  # cd(testdir)
  # Pkg.activate(".")


  # @testitem "Autostart app" setup=[GenieTestSetup] begin
  #   using Genie

  #   workdir = Base.Filesystem.mktempdir()

  #   Genie.Generator.newapp(workdir, autostart = true, testmode = true)

  #   @test true === true
  # end;


  cd(testdir)
  Pkg.activate(".")


  @testitem "Microstack file structure" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.Generator.newapp(workdir, autostart = false, testmode = true)

    @test sort(readdir(workdir)) == sort([".gitattributes", ".gitignore", "Manifest.toml", "Project.toml", "bin",
                                          "bootstrap.jl", "config", "genie.jl", "public", "routes.jl", "src"])
    @test readdir(joinpath(workdir, Genie.config.path_initializers)) == ["autoload.jl", "converters.jl", "logging.jl", "ssl.jl"]

    # TODO: add test for files in /src /config /public and /bin
  end;


  cd(testdir)
  Pkg.activate(".")


  @testitem "DB support file structure" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.Generator.newapp(workdir, autostart = false, dbsupport = true, testmode = true)

    @test sort(readdir(workdir)) == sort([".gitattributes", ".gitignore", "Manifest.toml", "Project.toml", "bin",
                                          "bootstrap.jl", "config", "db", "genie.jl", "public", "routes.jl", "src"])
    @test sort(readdir(joinpath(workdir, Genie.config.path_db))) == sort(["connection.yml", "migrations", "seeds"])
    @test sort(readdir(joinpath(workdir, Genie.config.path_initializers))) == sort(["autoload.jl", "converters.jl", "logging.jl", "searchlight.jl", "ssl.jl"])
  end;


  cd(testdir)
  Pkg.activate(".")


  @testitem "MVC support file structure" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.Generator.newapp(workdir, autostart = false, mvcsupport = true, testmode = true)

    @test sort(readdir(workdir)) == sort([".gitattributes", ".gitignore", "Manifest.toml", "Project.toml", "app", "bin", "bootstrap.jl", "config", "genie.jl", "public", "routes.jl", "src"])
    @test sort(readdir(joinpath(workdir, Genie.config.path_app))) == sort(["helpers", "layouts", "resources"])
    @test sort(readdir(joinpath(workdir, Genie.config.path_initializers))) == sort(["autoload.jl", "converters.jl", "logging.jl", "ssl.jl"])
  end;


  cd(testdir)
  Pkg.activate(".")


  @testitem "New controller" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.Generator.newcontroller("Yazoo")

    @test isdir(joinpath(workdir, "app", "resources", "yazoo")) == true
    @test isfile(joinpath(workdir, "app", "resources", "yazoo", "YazooController.jl")) == true
  end;

  cd(testdir)
  Pkg.activate(".")


  @testitem "New resource" setup=[GenieTestSetup] begin
    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.newresource("Kazoo")

    @test isdir(joinpath(workdir, "app", "resources", "kazoo")) == true
    @test isfile(joinpath(workdir, "app", "resources", "kazoo", "KazooController.jl")) == true
  end;


  cd(testdir)
  Pkg.activate(".")


  @testitem "New task" setup=[GenieTestSetup] begin
    using Genie, Genie.Exceptions

    workdir = Base.Filesystem.mktempdir()

    cd(workdir)

    Genie.newtask("Vavoom")

    @test isdir(joinpath(workdir, "tasks")) == true
    @test isfile(joinpath(workdir, "tasks", "VavoomTask.jl")) == true
    @test_throws FileExistsException Genie.newtask("Vavoom")
  end;


  cd(testdir)
  Pkg.activate(".")


end;

=#