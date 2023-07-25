@safetestset "Testing the eager loading of Env" begin
  using Genie

  # environment should be loaded from .env file
  @test ENV["TESTVAL"] == "12345"
end