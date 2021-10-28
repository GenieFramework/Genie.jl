@safetestset "Assets rendering" begin

  @safetestset "Embedded assets" begin
    using Genie
    using Genie.Renderer
    using Genie.Assets

    @test (Assets.js_settings() * Assets.embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), type="js", file="channels"))) == Assets.channels()

    @test Assets.channels()[1:18] == "window.Genie = {};"

    @test Assets.channels_script()[1:28] == "<script>\nwindow.Genie = {};\n"
  end;

end;