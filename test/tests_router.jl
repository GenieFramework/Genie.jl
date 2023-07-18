@safetestset "Router tests" begin

  @safetestset "Basic routing" begin
    using Genie, Genie.Router

    route("/hello") do _
      "Hello"
    end

  end;

  @safetestset "router_delete" begin
    using Genie, Genie.Router

    x = route("/caballo") do _
      "caballo"
    end

    @test (x in routes()) == true
    Router.delete!(:get_caballo)
    @test (x in routes()) == false
  end;

  @safetestset "isroute checks" begin
    using Genie, Genie.Router

    @test Router.isroute(:get_abcd) == false
    route("/abcd", named = :get_abcd) do _
      "abcd"
    end
    @test Router.isroute(:get_abcd) == true
  end;

  @safetestset "test to_url" begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do _
      "abcd"
    end

    @test Router.to_url(Params(), :get_abcd) == "/abcd"
  end

  @safetestset "test with basepath" begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do _
      "abcd"
    end

    @test Router.to_url(Params(), :get_abcd, basepath = "/geniedev/9001") == "/geniedev/9001/abcd"
  end

end;