@testset "No query params" begin
  using Genie
  using HTTP

  port = rand(8500:8900)

  route("/") do
    isempty(query()) && return ""
    isempty(params(:GET)) && return ""

    "error"
  end

  up(port; open_browser = false)

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test isempty(String(response.body)) == true

  down()
  sleep(1)
end


@testset "No defaults errors out" begin
  using Genie
  using HTTP

  port = rand(8500:8900)

  route("/") do
    query(:a)
  end

  up(port; open_browser = false)

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 500

  down()
  sleep(1)
end


@testset "Defaults when no query params" begin
  using Genie
  using HTTP

  port = rand(8500:8900)

  route("/") do
    query(:x, "10") * query(:y, "20")
  end

  up(port; open_browser = false)

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "1020"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "1020"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "20"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x&a=3", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "20"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x&y", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test isempty(String(response.body)) == true

  down()
  sleep(1)
end


@testset "Query params processing" begin
  using Genie
  using HTTP

  port = rand(8500:8900)

  route("/") do
    query(:x)
  end

  up(port; open_browser = false)

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port?x=1", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "1"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port?x=1&x=2", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "2"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port?x=1&x=2&x=3", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "3"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port?x=1&x=2&x=3&y=0", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "3"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port?x=0&x[]=1&x[]=2", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "0"

  down()
  sleep(1)
end


@testset "Array query params" begin
  using Genie
  using HTTP

  port = rand(8500:8900)

  route("/") do
    query(:x, "10") * join(query(Symbol("x[]"), "100"))
  end

  up(port; open_browser = false)

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "10100"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x&x[]=1000", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "1000"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x&x[]=1000&x[]=2000", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "10002000"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x=9&x[]=1000&x[]=2000", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "910002000"

  # ====

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port/?x=9&x[]=1000&x[]=2000&y[]=8", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == "910002000"

  down()
  sleep(1)
end