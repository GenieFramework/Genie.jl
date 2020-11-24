@testset "Query GET params features" begin

  @testset "No query params" begin
    using Genie
    using HTTP

    route("/") do
      isempty(Genie.Router.@query()) && return ""
      isempty(@params(:GET)) && return ""
      "error"
    end

    Genie.up(; open_browser = false)

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test isempty(String(response.body)) == true

    down()
  end;


  @testset "No defaults errors out" begin
    using Genie
    using HTTP

    route("/") do
      @query(:a)
    end

    Genie.up(; open_browser = false)

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 500

    down()
  end;


  @testset "Defaults when no query params" begin
    using Genie
    using HTTP

    route("/") do
      @query(:x, "10") * @query(:y, "20")
    end

    Genie.up(; open_browser = false)

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "1020"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "1020"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "20"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x&a=3", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "20"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x&y", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test isempty(String(response.body)) == true

    down()
  end;


  @testset "Query params processing" begin
    using Genie
    using HTTP

    route("/") do
      @query(:x)
    end

    Genie.up(; open_browser = false)

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000?x=1", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "1"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000?x=1&x=2", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "2"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000?x=1&x=2&x=3", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "3"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000?x=1&x=2&x=3&y=0", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "3"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000?x=0&x[]=1&x[]=2", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "0"

    down()
  end;


  @testset "Array query params" begin
    using Genie
    using HTTP

    route("/") do
      @query(:x, "10") * join(@query(Symbol("x[]"), "100"))
    end

    Genie.up(; open_browser = false)

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "10100"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x&x[]=1000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "1000"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x&x[]=1000&x[]=2000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "10002000"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x=9&x[]=1000&x[]=2000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "910002000"

    # ====

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000/?x=9&x[]=1000&x[]=2000&y[]=8", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "910002000"

    down()
  end;

end;