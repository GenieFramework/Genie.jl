# @testitem "Router tests" begin

  @testitem "Basic routing" begin
    using Genie, Genie.Router

    route("/hello") do
      "Hello"
    end

  end;

  @testitem "router_delete" begin
    using Genie, Genie.Router

    x = route("/caballo") do
      "caballo"
    end

    @test (x in routes()) == true
    Router.delete!(:get_caballo)
    @test (x in routes()) == false
  end;

  @testitem "isroute checks" begin
    using Genie, Genie.Router

    @test Router.isroute(:get_abcde) == false
    route("/abcde", named = :get_abcde) do
      "abcde"
    end
    @test Router.isroute(:get_abcde) == true
  end;

  @testitem "test to_link" begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do
      "abcd"
    end

    @test Router.to_link(:get_abcd) == "/abcd"
  end

  @testitem "test with basepath" begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do
      "abcd"
    end
    
    @test Router.to_link(:get_abcd, basepath = "/geniedev/9001") == "/geniedev/9001/abcd"
  end

# end;