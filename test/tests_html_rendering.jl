@safetestset "HTML rendering" begin
  using Genie, Genie.Renderer.Html, Genie.Requests

  greeting = "Welcome"
  name = "Genie"

  function htmlviewfile()
    "
    <h1>$greeting</h1>
    <div>
      <p>This is a $name test</p>
    </div>
    <hr />
    "
  end

  function htmltemplatefile()
    "
    <!DOCTYPE HTML>
    <html>
    <head>
      <title>$name test</title>
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


  @testset "HTML Rendering" begin
    using Genie, Genie.Renderer.Html, Genie.Requests

    @testset "WebRenderable constructors" begin
      using Genie, Genie.Renderer.Html, Genie.Requests

      wr = Genie.Renderer.WebRenderable("hello")
      @test wr.body == "hello"
      @test wr.content_type == Genie.Renderer.DEFAULT_CONTENT_TYPE
      @test wr.status == 200
      @test wr.headers == Genie.Renderer.HTTPHeaders()

      wr = Genie.Renderer.WebRenderable("hello", :json)
      @test wr.body == "hello"
      @test wr.content_type == :json
      @test wr.status == 200
      @test wr.headers == Genie.Renderer.HTTPHeaders()

      wr = Genie.Renderer.WebRenderable()
      @test wr.body == ""
      @test wr.content_type == Genie.Renderer.DEFAULT_CONTENT_TYPE
      @test wr.status == 200
      @test wr.headers == Genie.Renderer.HTTPHeaders()

      wr = Genie.Renderer.WebRenderable(body = "bye", content_type = :javascript, status = 301, headers = Genie.Renderer.HTTPHeaders("Location" => "/bye"))
      @test wr.body == "bye"
      @test wr.content_type == :javascript
      @test wr.status == 301
      @test wr.headers["Location"] == "/bye"

      wr = Genie.Renderer.WebRenderable(Genie.Renderer.WebRenderable(body = "good morning", content_type = :javascript), 302, Genie.Renderer.HTTPHeaders("Location" => "/morning"))
      @test wr.body == "good morning"
      @test wr.content_type == :javascript
      @test wr.status == 302
      @test wr.headers["Location"] == "/morning"
    end;

    @testset "String HTML rendering" begin
      using Genie, Genie.Renderer.Html, Genie.Requests
      import Genie.Util: fws

      r = Requests.HTTP.Response()

      @testset "String no layout" begin
        r = html(htmlviewfile(), forceparse = true)

        @test String(r.body) |> fws ==
              "<!DOCTYPE html><html><body><h1>$greeting</h1><div><p>This is a $name test</p></div>
              <hr$(Genie.config.html_parser_close_tag)></body></html>" |> fws
      end;

      @testset "String with layout" begin
        r = html(htmlviewfile(), layout = htmltemplatefile())

        @test String(r.body) |> fws ==
              "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\">
              <h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></div>
              <footer>Just a footer</footer></body></html>" |> fws
      end;

      @testset "Rendering with params headers" begin
        p = Params()
        @test isempty(p[:response].headers)

        wr = WebRenderable("hello")
        @test isempty(wr.headers)

        wr.headers["X-Foo"] = "Bar"
        @test wr.headers["X-Foo"] == "Bar"

        setheaders(p, ["X-Foo-Bar" => "Bazinga", "Access-Control-Allow-Methods" => "GET, POST, OPTIONS"])
        @test Dict(p[:response].headers)["X-Foo-Bar"] == "Bazinga"
        @test Dict(p[:response].headers)["Access-Control-Allow-Methods"] == "GET, POST, OPTIONS"

        setheaders(p, ["X-Foo-Bar" => "Bazinga", "Access-Control-Allow-Methods" => "GET"])
        @test Dict(p[:response].headers)["Access-Control-Allow-Methods"] == "GET"

        wr = WebRenderable("bye", p)
        @test wr.headers["X-Foo-Bar"] == "Bazinga"
        @test wr.headers["Access-Control-Allow-Methods"] == "GET"
      end;

      @test r.status == 200
      @test Dict(r.headers[1])["Content-Type"] == "text/html; charset=utf-8"
    end;
  end;
end