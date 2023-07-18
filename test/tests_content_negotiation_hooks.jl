@safetestset "Content negotiation hooks" begin
  using Genie, HTTP

  custom_message = "Got you!"
  original_message = "Hello!"

  function hook(req, res, params)
    if params[:route] !== nothing
      params[:route].action = (_::Params) -> custom_message
    end

    req, res, params
  end

  route("/") do _::Params
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
  Genie.Server.down!()

  sleep(1)
  server = nothing
  port = nothing
end