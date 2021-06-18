@safetestset "SVG API support in Renderer.Html" begin
  @safetestset "SVG API is available" begin
    using Genie
    using Genie.Renderer.Html

    @test svg() == "<svg></svg>"

    @test_throws UndefVarError clippath()
    @test clipPath() == "<clipPath></clipPath>"
  end;

end;