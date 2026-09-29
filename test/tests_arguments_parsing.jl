@testitem "Parsing of route arguments with types" setup=[GenieTestSetup] begin
  using Genie, Dates, HTTP
  Base.convert(::Type{Float64}, s::AbstractString) = parse(Float64, s)
  Base.convert(::Type{Int}, s::AbstractString) = parse(Int, s)
  Base.convert(::Type{Dates.Date}, s::AbstractString) = Date(s)

  orig = Genie.config.server_handler_mode
  
  route("/getparams/:s::String/:f::Float64/:i::Int/:d::Date", context = @__MODULE__) do
    "s = $(params(:s)) / f = $(params(:f)) / i = $(params(:i)) / $(params(:d))"
  end

  Genie.config.server_handler_mode = :distributed

  response = HTTP.get("http://localhost:$PORT/getparams/foo/23.43/18/2019-02-15")

  @test response.status == 200
  @test String(response.body) == "s = foo / f = 23.43 / i = 18 / 2019-02-15"

  Genie.config.server_handler_mode = :sequential

  response = HTTP.get("http://localhost:$PORT/getparams/foo/23.43/18/2019-02-15")

  @test response.status == 200
  @test String(response.body) == "s = foo / f = 23.43 / i = 18 / 2019-02-15"

  Genie.config.server_handler_mode = orig
end

@testitem "Parsing with multithreading"  setup=[GenieTestSetup] begin
  route("/debug/threadid") do
    id1 = Threads.threadid()
    id2 = fetch(Threads.@spawn Threads.threadid())
    d = id1 => id2
    println("thread info: $d")
    d
  end

  orig = Genie.config.server_handler_mode
  Genie.config.server_handler_mode = :threads

  for n in 1:Threads.nthreads()
    response = HTTP.get("http://localhost:$PORT/debug/threadid")
    @test contains(String(response.body), r"\d+ => \d+")
  end

  Genie.config.server_handler_mode = :sequential

  for n in 1:Threads.nthreads()
    response = HTTP.get("http://localhost:$PORT/debug/threadid")
    @test contains(String(response.body), r"\d+ => \d+")
  end

  Genie.config.server_handler_mode = orig
end