@safetestset "Flax rendering" begin

  @safetestset "Simple tag rendering" begin
    using Genie
    using Genie.Renderer

    copy = "Hello Genie"

    @test Html.p(copy) == "<p>$copy</p>"
    @test Html.div() == "<div></div>"
    @test Html.br() ==  "<br>"

    message = "Important message"
    @test Html.span(message, class = "focus") == "<span class=\"focus\">$message</span>"
    @test Html.span(message, class = "focus"; NamedTuple{(Symbol("data-process"),)}(("pre-process",))...) == "<span class=\"focus\" data-process=\"pre-process\">Important message</span>"
    @test Html.span("Important message", class = "focus"; NamedTuple{(Symbol("data-process"),)}(("pre-process",))...) do
            Html.a("Click here to read message")
          end == "<span class=\"focus\" data-process=\"pre-process\" Important message><a>Click here to read message</a></span>"
  end;

end;