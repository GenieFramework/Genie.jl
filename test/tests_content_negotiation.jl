# @testitem "Content negotiation" setup=[GenieTestSetup] begin

  @testitem "Response type matches request type" setup=[GenieTestSetup] begin
    @testset "Not found matches request type -- Content-Type -- custom HTML Genie page" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "text/html"], status_exception = false)

      @test response.status == 404
      @test occursin("Sorry, we can not find", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/html"

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["COnTeNT-TyPe" => "text/html"], status_exception = false)

      @test response.status == 404
      @test occursin("Sorry, we can not find", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/html"
    end

    @testset "Not found matches request type -- Accept -- custom HTML Genie page" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/html"], status_exception = false)

      @test response.status == 404
      @test occursin("Sorry, we can not find", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/html"

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["AcCePt" => "text/html"], status_exception = false)

      @test response.status == 404
      @test occursin("Sorry, we can not find", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/html"
    end

    @testset "Not found matches request type -- Content-Type -- custom JSON Genie handler" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "application/json"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["CoNtEnt-TyPe" => "application/json"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"
    end

    @testset "Not found matches request type -- Accept -- custom JSON Genie handler" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "application/json"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["acCepT" => "application/json"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"
    end

    @testset "Not found matches request type -- Content-Type -- custom text Genie handler" begin

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "text/plain"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/plain"

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["conTeNT-tYPE" => "text/plain"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/plain"
    end
  end;

  @testitem "Not found matches request type -- Content-Type -- unknown content type get same response" setup=[GenieTestSetup] begin
    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "text/csv"], status_exception = false)

    @test response.status == 404
    @test occursin("404 Not Found", String(response.body)) == true
    @test Dict(response.headers)["Content-Type"] == "text/csv"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["conTeNT-tYPE" => "text/csv"], status_exception = false)

    @test response.status == 404
    @test occursin("404 Not Found", String(response.body)) == true
    @test Dict(response.headers)["Content-Type"] == "text/csv"
  end

  @testitem "Not found matches request type -- Accept -- unknown content type get same response" setup=[GenieTestSetup] begin
    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/csv"], status_exception = false)

    @test response.status == 404
    @test occursin("404 Not Found", String(response.body)) == true
    @test Dict(response.headers)["Content-Type"] == "text/csv"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["accEPT" => "text/csv"], status_exception = false)

    @test response.status == 404
    @test occursin("404 Not Found", String(response.body)) == true
    @test Dict(response.headers)["Content-Type"] == "text/csv"
  end

  @testitem "Custom error handlers" setup=[GenieTestSetup] begin
    @testset "Custom error handler for unknown types" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "text/csv"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "text/csv"

      Genie.Router.error(error_message::String, ::Type{MIME"text/csv"}, ::Val{404}; error_info = "") = begin
        HTTP.Response(401, ["Content-Type" => "text/csv"], body = "Search CSV and you shall find")
      end

      try
        response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["conTeNT-tYPE" => "text/csv"], status_exception = false)

        @test response.status == 401
        @test occursin("Search CSV and you shall find", String(response.body)) == true
        @test Dict(response.headers)["Content-Type"] == "text/csv"

        response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["accept" => "text/csv"], status_exception = false)

        @test response.status == 401
        @test occursin("Search CSV and you shall find", String(response.body)) == true
        @test Dict(response.headers)["Content-Type"] == "text/csv"
      finally
        # Guarantees the process-wide override is undone even if a request above throws,
        # since other test items on the same worker share this Router.error method table.
        Base.delete_method.(methods(Genie.Router.error, (String, Type{MIME"text/csv"}, Val{404})))
      end
    end

    @testset "Custom error handler for known types" begin
      response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Content-Type" => "application/json"], status_exception = false)

      @test response.status == 404
      @test occursin("404 Not Found", String(response.body)) == true
      @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"

      Genie.Router.error(error_message::String, ::Type{MIME"application/json"}, ::Val{404}; error_info = "") = begin
        HTTP.Response(401, ["Content-Type" => "application/json"], body = "Search CSV and you shall find")
      end

      try
        response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["conTeNT-tYPE" => "application/json"], status_exception = false)

        @test response.status == 401
        @test occursin("Search CSV and you shall find", String(response.body)) == true
        @test Dict(response.headers)["Content-Type"] == "application/json"

        response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["accept" => "application/json"], status_exception = false)

        @test response.status == 401
        @test occursin("Search CSV and you shall find", String(response.body)) == true
        @test Dict(response.headers)["Content-Type"] == "application/json"
      finally
        # Genie already ships a specific method for this exact signature
        # (src/renderers/Json.jl:111), and the redefinition above replaced it rather than
        # shadowing it, since both share the same signature. On Julia 1.10,
        # `Base.delete_method` on the replacement does NOT bring the original back — it
        # leaves no specific method at all, so dispatch permanently falls through to the
        # generic `mime::Any` handler for the rest of this worker's tests, which formats
        # Content-Type without the "; charset=utf-8" suffix (verified directly: same
        # sequence, same Genie code, only the Julia version differs). Julia 1.11+ happens
        # to revive the original method on delete, which is why this doesn't reproduce
        # locally on newer Julia. Restore the original body explicitly so behavior doesn't
        # depend on that version difference, and wrap in `try`/`finally` so it still
        # happens even if a request above throws.
        Genie.Router.error(error_message::String, ::Type{MIME"application/json"}, ::Val{404}; error_info::String = "") = begin
          Genie.Renderer.Json.json(Dict("error" => "404 Not Found - $error_message", "info" => error_info), status = 404)
        end
      end
    end
  end
  @testitem "Order of accept preferences" setup=[GenieTestSetup] begin
    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/html, text/plain, application/json, text/csv"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "text/html"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/plain, application/json, text/csv, text/html"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "text/plain"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "application/json, text/csv, text/html, text/plain"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/csv, text/html, text/plain, application/json"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "text/html"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/csv, text/plain, application/json, text/html"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "text/plain"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/csv, application/json, text/html, text/plain"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/notexisting", ["Accept" => "text/csv"], status_exception = false)

    @test Dict(response.headers)["Content-Type"] == "text/csv"
  end

# end;