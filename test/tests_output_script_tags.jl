@safetestset "Output <script> tags" begin
  using Genie, Genie.Renderer
  using Genie.Renderer.Html
  import Genie.Util: fws

  @test Html.html("""<body><p>Good morning</p><script>alert("Hello")</script></body>""").body |> String ==
    """<body><p>Good morning</p><script>alert("Hello")</script></body>"""

  @test Html.html("""<body><p>Good morning</p><script type="text/javascript">alert("Hello")</script></body>""").body |> String ==
    """<body><p>Good morning</p><script type="text/javascript">alert("Hello")</script></body>"""

  @test Html.html("""<body><p>Good morning</p><script src="foo.js"></script></body>""").body |> String ==
    """<body><p>Good morning</p><script src="foo.js"></script></body>"""

  @test Html.html("""<body><p>Good morning</p><script type="text/javascript" src="foo.js"></script></body>""").body |> String ==
    """<body><p>Good morning</p><script type="text/javascript" src="foo.js"></script></body>"""

  @test Html.html("""<body><p>Good morning</p><script type="text/vbscript" src="foo.vb"></script></body>""").body |> String ==
    """<body><p>Good morning</p><script type="text/vbscript" src="foo.vb"></script></body>"""

  @test Html.html(filepath("views/outputscripttags.jl.html")).body |> String |> fws ==
    """<!DOCTYPE html><html><body><p>Greetings</p><script>alert("Hello")</script><script src="foo.js">
    </script><script type="text/javascript">alert("Hello")</script><script type="text/javascript" src="foo.js"></script></body></html>""" |> fws

  @test Html.html(filepath("views/outputscripttags.jl.html"), layout=filepath("views/layoutscripttags.jl.html")).body |> String |> fws ==
    """<!DOCTYPE html><html><body><h1>Layout header</h1><section><p>Greetings</p><script>alert("Hello")</script><script src="foo.js">
    </script><script type="text/javascript">alert("Hello")</script><script type="text/javascript" src="foo.js"></script>
    </section><footer><h4>Layout footer</h4></footer><script>alert("Hello")</script><script src="foo.js"></script>
    <script type="text/javascript">alert("Hello")</script><script type="text/javascript" src="foo.js"></script></body></html>""" |> fws
end