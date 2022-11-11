@safetestset "basic rendering" begin
  using Genie
  using Genie.Renderer.Html
  using Genie.Requests
  import Genie.Util: fws

  content = "abcd"
  content2 = "efgh"
  content3 = "\$hello\$"

  @testset "Basic rendering" begin
    r = Requests.HTTP.Response()


    @testset "Empty string" begin
      r = html("")

      @test String(r.body) == ""
    end;

    # @testset "Empty string force parse" begin
    #   @test_throws ArgumentError html("", forceparse = true)
    # end;


    @testset "String no spaces" begin
      r = html(content)

      @test String(r.body) == "$content"
    end;

    @testset "String with backspace dollar" begin
      r = html(content3)
      @test String(r.body) |> fws == raw"<!DOCTYPE html><html><body><p>$hello$</p></body></html>" |> fws
    end

    @testset "String no spaces force parse" begin
      r = html(content, forceparse = true)

      @test String(r.body) |> fws  == "<!DOCTYPE html><html><body><p>abcd</p></body></html>" |> fws
    end;


    @testset "String with 2 spaces" begin
      r = html("  $content  ")

      @test String(r.body) == "  abcd  "
    end;

    @testset "String with 2 spaces force parse" begin
      r = html("  $content  ", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>abcd  </p></body></html>" |> fws
    end;


    @testset "String with &nbsp;" begin
      r = html("  &nbsp;&nbsp;  ")

      @test String(r.body) == "  &nbsp;&nbsp;  "
    end;

    @testset "String with &nbsp; force parse" begin
      r = html("  &nbsp;&nbsp;  ", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>&nbsp;&nbsp;  </p></body></html>" |> fws
    end;


    @testset "String with 2 &nbsp; and 2 spaces" begin
      r = html("&nbsp;&nbsp;$content  ")

      @test String(r.body) == "&nbsp;&nbsp;abcd  "
    end;

    @testset "String with 2 &nbsp; and 2 spaces force parse" begin
      r = html("&nbsp;&nbsp;$content  ", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>&nbsp;&nbsp;abcd  </p></body></html>" |> fws
    end;


    @testset "String with newline" begin
      r = html("$content  \n  &nbsp;&nbsp;$content2")

      @test String(r.body) == "abcd  \n  &nbsp;&nbsp;efgh"
    end;

    @testset "String with newline force parse" begin
      r = html("$content  \n  &nbsp;&nbsp;$content2", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>abcd  \n&nbsp;&nbsp;efgh</p></body></html>" |> fws
    end;


    @testset "String with quotes" begin
      r = html("He said \"wow!\"")

      @test String(r.body) == "He said \"wow!\""
    end;

    @testset "String with quotes force parse" begin
      r = html("He said \"wow!\"", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>He said \"wow!\"\0</p></body></html>" |> fws
    end;


    @testset "String with quotes" begin
      r = html(""" "" """)

      @test String(r.body) == " \"\" "
    end;

    @testset "String with quotes force parse" begin
      r = html(""" "" """, forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>\"\" </p></body></html>" |> fws
    end;


    @testset "String with quotes" begin
      r = html("\"\"")

      @test String(r.body) == "\"\""
    end;

    @testset "String with quotes force parse" begin
      r = html("\"\"", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>\"\"\0</p></body></html>" |> fws
    end;


    @testset "String with interpolated vars" begin
      r = html("$(reverse(content))")

      @test String(r.body) == "dcba"
    end;

    @testset "String with interpolated vars force parse" begin
      r = html("$(reverse(content))", forceparse = true)

      @test String(r.body) |> fws == "<!DOCTYPE html><html><body><p>dcba</p></body></html>" |> fws
    end;


    @test r.status == 200
    @test r.headers[1]["Content-Type"] == "text/html; charset=utf-8"
  end;
end