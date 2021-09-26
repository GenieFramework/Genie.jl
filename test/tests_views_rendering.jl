@safetestset "HTML+Julia rendering" begin

  @safetestset "Simple tag rendering" begin
    using Genie
    using Genie.Renderer.Html
    import Genie.Util: fws

    copy = "Hello Genie"
    @test Html.p(copy) |> fws == "<p>$copy</p>" |> fws

    @test Html.div() |> fws == "<div></div>" |> fws

    @test Html.br() |> fws ==  "<br$(Genie.config.html_parser_close_tag)>" |> fws

    message = "Important message"
    @test Html.span(message, class = "focus") |> fws ==
          "<span class=\"focus\">$message</span>" |> fws

    @test Html.span(message, class = "focus"; NamedTuple{(Symbol("data-process"),)}(("pre-process",))...) |> fws ==
          "<span class=\"focus\" data-process=\"pre-process\">Important message</span>" |> fws

    @test Html.span("Important message", class = "focus"; NamedTuple{(Symbol("data-process"),)}(("pre-process",))...) do
            Html.a("Click here to read message")
          end |> fws ==
          "<span class=\"focus\" data-process=\"pre-process\" Important message><a>Click here to read message</a></span>" |> fws
  end;

end;