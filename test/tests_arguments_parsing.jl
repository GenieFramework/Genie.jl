@safetestset "Parsing of route arguments with types" begin

  using Genie, Dates, HTTP

  Base.convert(::Type{Float64}, s::AbstractString) = parse(Float64, s)
  Base.convert(::Type{Int}, s::AbstractString) = parse(Int, s)
  Base.convert(::Type{Dates.Date}, s::AbstractString) = Date(s)

  route("/getparams/:s::String/:f::Float64/:i::Int/:d::Date", context = @__MODULE__) do
    "s = $(params(:s)) / f = $(params(:f)) / i = $(params(:i)) / $(params(:d))"
  end

  port = rand(8500:8900)

  server = up(port; open_browser = false)

  response = HTTP.get("http://localhost:$port/getparams/foo/23.43/18/2019-02-15")

  @test response.status == 200
  @test String(response.body) == "s = foo / f = 23.43 / i = 18 / 2019-02-15"

  down()
  sleep(1)
  server = nothing

end