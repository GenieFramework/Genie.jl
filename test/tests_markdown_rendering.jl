@safetestset "Markdown rendering" begin

  @safetestset "String markdown rendering" begin
    using Genie
    using Genie.Renderer.Html
    using Markdown
    import Genie.Util: fws

    view = raw"""
# Hello
## Welcome to Genie""" |> Markdown.parse

    @test (Html.html(view, forceparse = true).body |> String |> fws) ==
          "<!DOCTYPE html><html><body><h1>Hello</h1><h2>Welcome to Genie</h2></body></html>" |> fws

    view = raw"""
# Hello
## Welcome to Genie, $name""" |> Markdown.parse

    @test (Html.html(view, name = "John").body |> String |> fws) ==
          "<!DOCTYPE html><html><body><h1>Hello</h1><h2>Welcome to Genie, John</h2></body></html>" |> fws

    layout = raw"""
<div>
  <h1>Layout header</h1>
  <section>
    <% @yield %>
  </section>
  <footer>
    <h4>Layout footer</h4>
  </footer>
</div>"""

    @test (Html.html(view, layout = layout, name = "John").body |> String |> fws) ==
            "<!DOCTYPE html><html><body><div><h1>Layout header</h1><section><h1>Hello</h1><h2>Welcome to Genie, John</h2>
            </section><footer><h4>Layout footer</h4></footer></div></body></html>" |> fws
  end;

  @safetestset "Template markdown rendering" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html
    import Genie.Util: fws

    @test Html.html(filepath("views/view.jl.md"), numbers = [1, 1, 2, 3, 5, 8, 13]).body |> String |> fws ==
    """
      <!DOCTYPE html><html><head></head><body><h1>There are 7</h1>
      <p>-&gt; 1 -&gt; 1 -&gt; 2 -&gt; 3 -&gt; 5 -&gt; 8 -&gt; 13</p>
      </body></html>""" |> fws

    @test Html.html(filepath("views/view.jl.md"), layout = filepath("views/layout.jl.html"), numbers = [1, 1, 2, 3, 5, 8, 13]).body |> String |> fws ==
    """
      <!DOCTYPE html><html><body><div><h1>Layout header</h1><section><h1>There are 7</h1>
      <p>-&gt; 1 -&gt; 1 -&gt; 2 -&gt; 3 -&gt; 5 -&gt; 8 -&gt; 13</p>
      </section><footer><h4>Layout footer</h4></footer></div></body></html>""" |> fws
  end

  @safetestset "Markdown rendering with embedded variables" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html
    import Genie.Util: fws

    @test Html.html(filepath("views/view-vars.jl.md")).body |> String |> fws ==
      """
      <!DOCTYPE html><html><head></head><body><h1>There are 7</h1>
      <p>-&gt; 1 -&gt; 1 -&gt; 2 -&gt; 3 -&gt; 5 -&gt; 8 -&gt; 13</p>
      </body></html>""" |> fws
  end;

end;