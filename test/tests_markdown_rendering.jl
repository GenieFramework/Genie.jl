@safetestset "Markdown rendering" begin

  @safetestset "String markdown rendering" begin
    using Genie
    using Genie.Renderer.Html
    using Markdown

    view = raw"""
# Hello
## Welcome to Genie""" |> Markdown.parse

    @test (Html.html(view, forceparse = true).body |> String) == "<!DOCTYPE html><html><head></head><body><h1>Hello</h1><h2>Welcome to Genie</h2></body></html>"

    view = raw"""
# Hello
## Welcome to Genie, $name""" |> Markdown.parse

    @test (Html.html(view, name = "John").body |> String) == "<!DOCTYPE html><html><head></head><body><h1>Hello</h1><h2>Welcome to Genie, John</h2></body></html>"

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

    @test (Html.html(view, layout = layout, name = "John").body |> String) == "<!DOCTYPE html><html><head></head><body><div><h1>Layout header</h1><section><h1>Hello</h1><h2>Welcome to Genie, John</h2></section><footer><h4>Layout footer</h4></footer></div></body></html>"
  end;

  @safetestset "Template markdown rendering" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html

    @test Html.html(filepath("views/view.jl.md"), numbers = [1, 1, 2, 3, 5, 8, 13]).body |> String == "<!DOCTYPE html><html><head></head><body><h1>There are 7</h1><p>-> 1      -> 1      -> 2      -> 3      -> 5      -> 8      -> 13</p></body></html>"
    @test Html.html(filepath("views/view.jl.md"), layout = filepath("views/layout.jl.html"), numbers = [1, 1, 2, 3, 5, 8, 13]).body |> String ==
      "<!DOCTYPE html><html><head></head><body><div><h1>Layout header</h1><section><h1>There are 7</h1><p>-> 1      -> 1      -> 2      -> 3      -> 5      -> 8      -> 13</p></section><footer><h4>Layout footer</h4></footer></div></body></html>"
  end

  @safetestset "Markdown rendering with embedded variables" begin
    using Genie, Genie.Renderer
    using Genie.Renderer.Html

    @test Html.html(filepath("views/view-vars.jl.md")).body |> String == "<!DOCTYPE html><html><head></head><body><h1>There are 7</h1><p>-> 1      -> 1      -> 2      -> 3      -> 5      -> 8      -> 13</p></body></html>"
  end;

end;