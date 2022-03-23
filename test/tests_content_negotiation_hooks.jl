@safetestset "Content negotiation hooks" begin
  using Genie, HTTP

  custom_message = "Got you!"
  original_message = "Hello!"

  function hook(req, res, params)
    if haskey(params, :ROUTE)
      params[:ROUTE].action = () -> custom_message
    end

    req, res, params
  end

  route("/") do
    original_message
  end

  port = nothing
  port = rand(8500:8900)

  server = up(port)

  response = HTTP.request("GET", "http://localhost:$port")
  @test response.status == 200
  @test String(response.body) == original_message


  push!(Genie.Router.content_negotiation_hooks, hook)

  response = HTTP.request("GET", "http://localhost:$port")
  @test response.status == 200
  @test String(response.body) == custom_message

  pop!(Genie.Router.content_negotiation_hooks)
  Genie.AppServer.down!()

  sleep(1)
  server = nothing
  port = nothing
end