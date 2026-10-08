# @testitem "Router tests" setup=[GenieTestSetup] begin

  @testitem "Basic routing" setup=[GenieTestSetup] begin
    using Genie, Genie.Router

    route("/hello") do
      "Hello"
    end

  end;

  @testitem "router_delete" setup=[GenieTestSetup] begin
    using Genie, Genie.Router

    x = route("/caballo") do
      "caballo"
    end

    @test (x in routes()) == true
    Router.delete!(:get_caballo)
    @test (x in routes()) == false
  end;

  @testitem "isroute checks" setup=[GenieTestSetup] begin
    using Genie, Genie.Router

    @test Router.isroute(:get_abcde) == false
    route("/abcde", named = :get_abcde) do
      "abcde"
    end
    @test Router.isroute(:get_abcde) == true
    Router.delete!(:get_abcde)
    @test Router.isroute(:get_abcde) == false
  end;

  @testitem "test to_link" setup=[GenieTestSetup] begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do
      "abcd"
    end

    @test Router.to_link(:get_abcd) == "/abcd"
  end

  @testitem "test with basepath" setup=[GenieTestSetup] begin
    using Genie, Genie.Router

    route("/abcd", named = :get_abcd) do
      "abcd"
    end
    
    @test Router.to_link(:get_abcd, basepath = "/geniedev/9001") == "/geniedev/9001/abcd"
  end

  @testitem "request_type falls back to :html when no Accept/Content-Type header is sent" setup=[GenieTestSetup] begin
    using Genie, Genie.Router, HTTP

    # Regression test: the fallback used to do Symbol(request_mappings()[:html]),
    # which stringifies the ["text/html"] Vector instead of returning the :html key,
    # producing a garbage symbol instead of a usable CONTENT_TYPES key.
    @test Router.request_type(HTTP.Request("GET", "/")) == :html
  end

# end;