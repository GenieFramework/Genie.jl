@safetestset "SVG API support in Renderer.Html" begin

  @safetestset "SVG API is available" begin
    using Genie
    using Genie.Renderer.Html
    import Genie.Util: fws

    @test svg() |> fws == "<svg></svg>" |> fws

    @test_throws UndefVarError clippath()

    @test clipPath() |> fws == "<clipPath></clipPath>" |> fws
  end;

end;