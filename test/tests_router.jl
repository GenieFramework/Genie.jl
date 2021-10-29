@safetestset "Router tests" begin

  @safetestset "Basic routing" begin
    using Genie, Genie.Router

    route("/hello") do
      "Hello"
    end

  end;

  @safetestset "router_delete" begin
    using Genie, Genie.Router

    x = route("/caballo") do 
      "caballo"
    end

    @test (x in routes()) == true
    Router.delete!(:get_caballo)
    @test (x in routes()) == false
  end;

end;