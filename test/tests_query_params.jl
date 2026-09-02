# @testitem "Query params" setup=[GenieTestSetup] begin

@testitem "No query params" setup=[GenieTestSetup] begin
  route("/") do
    isempty(query()) && return ""
    isempty(params(:GET)) && return ""

    "error"
  end

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 200
  @test isempty(String(response.body)) == true
end


@testitem "No defaults errors out" setup=[GenieTestSetup] begin
  route("/") do
    query(:a)
  end

  response = try
    HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
  catch ex
    ex.response
  end

  @test response.status == 500
end


@testitem "Defaults when no query params" setup=[GenieTestSetup] begin
  route("/") do
    query(:x, "10") * query(:y, "20")
  end

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
end


@testitem "Query params processing" setup=[GenieTestSetup] begin
  route("/") do
    query(:x)
  end

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
end


@testitem "Array query params" setup=[GenieTestSetup] begin
  route("/") do
    query(:x, "10") * join(query(Symbol("x[]"), "100"))
  end

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
end

# end