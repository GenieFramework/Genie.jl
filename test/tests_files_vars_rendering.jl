@safetestset "Files vars rendering" begin
  using Genie
  using Genie.Renderer.Html, Genie.Requests
  using Random
  import Base.Filesystem: mktemp

  greeting = "Welcome"
  name = "Genie"

  function htmlviewfile_withvars()
    raw"
    <h1>$(vars(:greeting))</h1>
    <div>
      <p>This is a $(vars(:name)) test</p>
    </div>
    <hr />
    "
  end

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

  viewfile = mktemp()
  write(viewfile[2], htmlviewfile_withvars())
  close(viewfile[2])

  templatefile = mktemp()
  write(templatefile[2], htmltemplatefile_withvars())
  close(templatefile[2])

  @testset "HTML rendering with view files" begin
    using Genie
    using Genie.Renderer.Html, Genie.Requests

    r = Requests.HTTP.Response()

    @testset "HTML rendering with view file no layout with vars" begin
      r = html(Genie.Renderer.Path(viewfile[1]), greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head></head><body><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></body></html>"
    end;

    @testset "HTML rendering with view file and layout with vars" begin
      r = html(Genie.Renderer.Path(viewfile[1]), layout = Genie.Renderer.Path(templatefile[1]), greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\"><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)>\n</div><footer>Just a footer</footer></body></html>"
    end;

    @test r.status == 200
    @test r.headers[1]["Content-Type"] == "text/html; charset=utf-8"

    @testset "HTML rendering with view file no layout with vars custom headers" begin
      r = html(Genie.Renderer.Path(viewfile[1]), headers = Genie.Renderer.HTTPHeaders("Cache-Control" => "no-cache"), greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head></head><body><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></body></html>"
      @test r.headers[1]["Cache-Control"] == "no-cache"
    end;

    @testset "HTML rendering with view file and layout with vars custom headers" begin
      r = html(Genie.Renderer.Path(viewfile[1]), layout = Genie.Renderer.Path(templatefile[1]), headers = Genie.Renderer.HTTPHeaders("Cache-Control" => "no-cache"), greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\"><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)>\n</div><footer>Just a footer</footer></body></html>"
      @test r.headers[1]["Cache-Control"] == "no-cache"
    end;

    @testset "HTML rendering with view file no layout with vars custom headers custom status" begin
      r = html(Genie.Renderer.Path(viewfile[1]), headers = Genie.Renderer.HTTPHeaders("Cache-Control" => "no-cache"), status = 500, greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head></head><body><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)></body></html>"
      @test r.headers[1]["Cache-Control"] == "no-cache"
      @test r.status == 500
    end;

    @testset "HTML rendering with view file and layout with vars custom headers custom status" begin
      r = html(Genie.Renderer.Path(viewfile[1]), layout = Genie.Renderer.Path(templatefile[1]),
                headers = Genie.Renderer.HTTPHeaders("Cache-Control" => "no-cache"), status = 404, greeting = greeting, name = Genie)

      @test String(r.body) == "<!DOCTYPE html><html><head><title>$name test</title></head><body><div class=\"template\"><h1>$greeting</h1><div><p>This is a $name test</p></div><hr$(Genie.config.html_parser_close_tag)>\n</div><footer>Just a footer</footer></body></html>"
      @test r.headers[1]["Cache-Control"] == "no-cache"
      @test r.status == 404
    end;
  end;
end;