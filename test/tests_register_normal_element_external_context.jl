@testitem "register_normal_element works in external module contexts (StippleUI pattern)" setup=[GenieTestSetup] begin
  # Mirrors how StippleUI component files register their tags, e.g. StippleUI/src/Buttons.jl:
  #   using Stipple                                                       # reexports Genie.Renderer.Html, brings in ParsedHTMLString
  #   import Genie.Renderer.Html: normal_element, register_normal_element # non-exported helper, imported explicitly
  #   register_normal_element("q__btn", context = @__MODULE__)
  # Note `_string` is never imported this way, because it is a private,
  # unexported helper of Genie.Renderer.Html.
  module FakeStippleComponent
    using Genie.Renderer.Html
    import Genie.Renderer.Html: normal_element, register_normal_element

    register_normal_element("gnrs__fake__elem", context = @__MODULE__)
  end

  using .FakeStippleComponent: gnrs__fake__elem

  # Function and String/Vector{String} children do not hit the `_string` helper, so they work.
  @test gnrs__fake__elem("plain string") == "<gnrs-fake-elem>plain string</gnrs-fake-elem>"

  # Any other children type (Symbol, Number, Vector{Any}, ...) is funneled through `_string`,
  # which is referenced unqualified in the generated code and is not visible in the caller's module.
  @test gnrs__fake__elem(:a_symbol) == "<gnrs-fake-elem>a_symbol</gnrs-fake-elem>"
  @test gnrs__fake__elem(Any["a", 1, "b"]) == "<gnrs-fake-elem>a1b</gnrs-fake-elem>"
end;
