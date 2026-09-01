# @testitem "Control flow rendering" setup=[GenieTestSetup] begin
  # @testitem "IF conditional rendering" setup=[GenieTestSetup] begin
    @testitem "IF true" setup=[GenieTestSetup] begin
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

    @testitem "IF false" setup=[GenieTestSetup] begin
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
  # end;
# end;