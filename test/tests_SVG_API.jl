@safetestset "SVG API support in Renderer.Html" begin

  @safetestset "" begin
    using Genie
    using Genie.Renderer.Html

    @test_throws UndefVarError svg()
  end;

  @safetestset "Loading SVG support makes SVG API available" begin
    using Genie
    using Genie.Renderer.Html

    Html.register_svg_elements()
    @test svg() == "<svg></svg>"

    @test_throws UndefVarError clippath()
    @test clipPath() == "<clipPath></clipPath>"
  end;

end;