@safetestset "Control flow rendering" begin
  @safetestset "IF conditional rendering" begin
    @safetestset "IF true" begin
      using Genie
      using Genie.Renderer.Html
      import Genie.Util: fws

      view = raw"""
                <section class='block'>
                  <% if true; [ %>
                    <h1>Hello</h1>
                    <p>Welcome</p>
                  <% ]end %>
                </section>"""

      @test String(html(view).body) |> fws ==
            """<!DOCTYPE html><html><body><section class="block"><h1>Hello</h1><p>Welcome</p></section></body></html>""" |> fws
    end;

    @safetestset "IF false" begin
      using Genie
      using Genie.Renderer.Html
      import Genie.Util: fws

      view = raw"""
                <section class='block'>
                  <% if false; [ %>
                    <h1>Hello</h1>
                    <p>Welcome</p>
                  <% ]end %>
                </section>"""

      @test String(html(view).body) |> fws ==
            """<!DOCTYPE html><html><body><section class="block"></section></body></html>""" |> fws
    end;
  end;
end;