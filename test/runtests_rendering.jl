using Genie.Renderer

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
  @testset "WebRenderable constructors" begin
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

    wr = Genie.Renderer.WebRenderable(body = "bye", content_type = :js, status = 301, headers = Dict("Location" => "/bye"))
    @test wr.body == "bye"
    @test wr.content_type == :js
    @test wr.status == 301
    @test wr.headers["Location"] == "/bye"

    wr = Genie.Renderer.WebRenderable(Genie.Renderer.WebRenderable(body = "good morning", content_type = :js), 302, Dict("Location" => "/morning"))
    @test wr.body == "good morning"
    @test wr.content_type == :js
    @test wr.status == 302
    @test wr.headers["Location"] == "/morning"
  end;

  @testset "String HTML rendering" begin
    r = Tester.HTTP.Response()

    @testset "String no layout" begin
      r = htmlviewfile() |> html

      @test String(r.body) == "<html><head></head><body><h1>$greeting</h1><div><p>This is a $name test</p></div><hr></body></html>"
    end;

    @testset "String with layout" begin
      r = html(htmlviewfile(), layout = htmltemplatefile())

      @test String(r.body) == "<html><head><title>$name test</title></head><body><div class=\"template\"><h1>$greeting</h1><div><p>This is a $name test</p></div><hr>\n</div><footer>Just a footer</footer></body></html>"
    end;

    @test r.status == 200
    @test r.headers[1]["Content-Type"] == "text/html; charset=utf-8"
  end;
end;