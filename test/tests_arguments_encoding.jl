@safetestset "Escaping quotes" begin
  @safetestset "Double quoted arguments" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html

    @test Html.html("""<body onload="alert('Hello');"><p>Good morning</p></body>""").body |> String ==
      """<body onload="alert('Hello');"><p>Good morning</p></body>"""

    @test Html.html("""<body onload="alert(\'Hello\');"><p>Good morning</p></body>""").body |> String ==
      """<body onload="alert('Hello');"><p>Good morning</p></body>"""

    @test Html.html("""<body onload="alert("Hello");"><p>Good morning</p></body>""").body |> String ==
      """<body onload="alert("Hello");"><p>Good morning</p></body>"""

    @test Html.html("""<body onload="alert(\"Hello\");"><p>Good morning</p></body>""").body |> String ==
      """<body onload="alert("Hello");"><p>Good morning</p></body>"""
  end

  @safetestset "Single quoted arguments" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html

    @test Html.html("""<body onload='alert(\'Hello\');'><p>Good morning</p></body>""").body |> String ==
      """<body onload='alert('Hello');'><p>Good morning</p></body>"""

    @test Html.html("""<body onload='alert("Hello");'><p>Good morning</p></body>""").body |> String ==
      """<body onload='alert("Hello");'><p>Good morning</p></body>"""

    @test Html.html("""<body onload='alert(\"Hello\");'><p>Good morning</p></body>""").body |> String ==
      """<body onload='alert("Hello");'><p>Good morning</p></body>"""
  end

  @safetestset "Arguments in templates" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html
    import Genie.Util: fws

    @test Html.html(filepath("views/argsencoded1.jl.html")).body |> String |> fws ==
          """<!DOCTYPE html><html><body><p onclick="alert('Hello');">Greetings</p></body></html>""" |> fws

    @test_throws LoadError Html.html(filepath("views/argsencoded2.jl.html")).body |> String ==
                  """<!DOCTYPE html><html><body><p onclick="alert("Hello");">Greetings</p></body></html>"""

    @test Html.html(filepath("views/argsencoded3.jl.html")).body |> String |> fws ==
          """<!DOCTYPE html><html><body><p onclick="alert('Hello');">Greetings</p></body></html>""" |> fws


    @test Html.html(filepath("views/argsencoded1.jl.html"), layout=filepath("views/layoutargsencoding.jl.html")).body |> String |> fws ==
          """<!DOCTYPE html><html><body><div style="width: '100px'"><h1>Layout header</h1><section>
              <p onclick="alert('Hello');">Greetings</p></section><footer><h4>Layout footer</h4></footer></div></body>
              </html>""" |> fws
  end
end