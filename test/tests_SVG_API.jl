@safetestset "SVG API support in Renderer.Html" begin

  @safetestset "" begin
    using Genie
    using Genie.Renderer.Html

    @test_throws UndefVarError svg()
  end;

  @safetestset "Update config when custom startup args" begin
    using Genie
    using Genie.Renderer.Html

    Html.register_svg_slements()
    @test svg() == "<svg></svg>"
  end;

end;