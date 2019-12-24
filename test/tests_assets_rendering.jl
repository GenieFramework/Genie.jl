@safetestset "Assets rendering" begin

  @safetestset "Embedded assets" begin
    using Genie
    using Genie.Renderer
    using Genie.Assets

    @test Assets.embedded(joinpath("files", "new_app", "public", "js", "app", "channels.js")) == Assets.channels()

    @test Assets.channels()[1:23] == "window.WebChannels = {}"

    @test Assets.channels_script()[1:34] == "<script>\nwindow.WebChannels = {};\n"
  end;

end;