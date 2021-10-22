@safetestset "Router tests" begin

  @safetestset "Basic routing" begin
    using Genie, Genie.Router

    route("/hello") do
      "Hello"
    end

  end;

  @safetestset "router_delete" begin
    using Genie, Genie.Router

    route("/hello") do
        "hello"
    end
    route("/bye") do
        "bye"
    end
    @test size(routes()) == (2,)
    Router.delete!(:get_bye)
    @test size(routes()) == (1,)
  end;
end;