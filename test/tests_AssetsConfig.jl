@safetestset "Assets config" begin
  using Genie, Genie.Assets

  @test Genie.Assets.AssetsConfig().host == Genie.config.base_path
  @test Genie.Assets.AssetsConfig().package == "Genie.jl"
  @test Genie.Assets.AssetsConfig().version == Genie.Assets.package_version("Genie.jl")

  @test Genie.Assets.AssetsConfig().host == Genie.Assets.assets_config.host
  @test Genie.Assets.AssetsConfig().package == Genie.Assets.assets_config.package
  @test Genie.Assets.AssetsConfig().version == Genie.Assets.assets_config.version

  Genie.Assets.assets_config!(host = "foo")
  @test Genie.Assets.assets_config.host == "foo"
end;
