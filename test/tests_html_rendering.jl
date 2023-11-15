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
        rm("build", force = true, recursive = true)
        r = html(htmlviewfile(), forceparse = true)

        @test String(r.body) |> fws ==
              "<!DOCTYPE html><html><body><h1>$greeting</h1><div><p>This is a $name test</p></div>
              <hr$(Genie.config.html_parser_close_tag)></body></html>" |> fws
      end;

      @testset "String with layout" begin
        rm("build", force = true, recursive = true)
        r = html(htmlviewfile(), layout = htmltemplatefile())

        @test String(r.body) |> fws ==
              "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\">
              <h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></div>
              <footer>Just a footer</footer></body></html>" |> fws
      end;

      @test r.status == 200
      @test r.headers[1]["Content-Type"] == "text/html; charset=utf-8"

      rm("build", force = true, recursive = true)
    end;

    @testset "Encoding Test" begin
        using Genie.Renderer, Genie.Renderer.Html

        path = mktempdir(cleanup=true)
        fpath = joinpath(path, "welcome.jl.html")

        write(fpath, "welcöme. 不一定要味道好，但一定要有用. äüö&%?#")

        expected = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n\r\n<!DOCTYPE html><html>\n  <body>\n    <p>welcöme. 不一定要味道好，但一定要有用. äüö&%?#\n</p>\n  </body></html>"

        decoded = String(html(filepath(fpath)))

        @test decoded == expected
    end

  end;
end
