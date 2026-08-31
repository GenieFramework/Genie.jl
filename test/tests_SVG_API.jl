# @testitem "SVG API support in Renderer.Html" setup=[GenieTestSetup] begin

  @testitem "SVG API is available" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    @test svg() |> fws == "<svg></svg>" |> fws

    @test_throws UndefVarError clippath()

    @test clipPath() |> fws == "<clipPath></clipPath>" |> fws
  end;

# end;