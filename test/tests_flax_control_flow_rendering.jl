@safetestset "Control flow rendering" begin
  @safetestset "IF conditional rendering" begin
    @safetestset "IF true" begin
      using Genie
      using Genie.Renderer.Html

      view = raw"""
                <section class='block'>
                  <% if true; [ %>
                    <h1>Hello</h1>
                    <p>Welcome</p>
                  <% ]end %>
                </section>"""

      @test String(html(view).body) == raw"<!DOCTYPE html><html><head></head><body><section class=\"block\"><h1>Hello</h1><p>Welcome</p></section></body></html>"
    end;

    @safetestset "IF false" begin
      using Genie
      using Genie.Renderer.Html

      view = raw"""
                <section class='block'>
                  <% if false; [ %>
                    <h1>Hello</h1>
                    <p>Welcome</p>
                  <% ]end %>
                </section>"""

      @test String(html(view).body) == raw"""<!DOCTYPE html><html><head></head><body><section class="block"></section></body></html>"""
    end;
  end;
end;