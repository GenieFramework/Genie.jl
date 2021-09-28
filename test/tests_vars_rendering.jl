@safetestset "Vars rendering" begin
  using Genie
  using Genie.Renderer.Html, Genie.Requests

  greeting = "Welcome"
  name = "Genie"

  """  
  $TYPEDSIGNATURES
  """
  function htmlviewfile_withvars()
    raw"
    <h1>$(vars(:greeting))</h1>
    <div>
      <p>This is a $(vars(:name)) test</p>
    </div>
    <hr />
    "
  end

  """  
  $TYPEDSIGNATURES
  """
  function htmltemplatefile_withvars()
    raw"
    <!DOCTYPE HTML>
    <html>
    <head>
      <title>$(vars(:name)) test</title>
    </head>
    <body>
      <div class=\"template\">
      <% @yield %>
      </div>
      <footer>Just a footer</footer>
    </body>
    </html>
    "
  end

  @testset "String HTML rendering with vars" begin
    using Genie
    using Genie.Renderer.Html, Genie.Requests
    import Genie.Util: fws

    r = Requests.HTTP.Response()

    @testset "String no layout with vars" begin
      r = html(htmlviewfile_withvars(), greeting = greeting, name = name)

      @test String(r.body) |> fws ==
            "<!DOCTYPE html><html><body><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)>
            </body></html>" |> fws
    end;

    @testset "String with layout with vars" begin
      r = html(htmlviewfile_withvars(), layout = htmltemplatefile_withvars(), greeting = "Welcome", name = "Genie")

      @test String(r.body) |> fws ==
            "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\"><h1>$greeting</h1>
            <div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></div><footer>Just a footer</footer>
            </body></html>" |> fws
    end;

    @test r.status == 200
    @test r.headers[1]["Content-Type"] == "text/html; charset=utf-8"
  end;
end;