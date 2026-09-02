# @testitem "Path traversal" setup=[GenieTestSetup] begin

  @testitem "Returns 401 unauthorised" setup=[GenieTestSetup] begin
    isdir(Genie.config.server_document_root) || mkdir(Genie.config.server_document_root)

    req = HTTP.request("GET", "http://localhost:$port////etc/hosts"; status_exception = false)
    @test req.status == (Sys.iswindows() ? 404 : 401)

    # req = HTTP.request("GET", "http://localhost:$port/../../src/mimetypes.jl"; status_exception = false)
    # @test req.status == 401
  end

  # Tests pass OK but for some reason some state remains and breaks next batch of tests... :-(
  # @testitem "Authorised static server responses" setup=[GenieTestSetup] begin
  #   using Genie
  #   using HTTP

  #   isdir(Genie.config.server_document_root) || mkdir(Genie.config.server_document_root)

  #   port = unique_test_port()
  #   server = Genie.Server.serve(; port)
  #   req = HTTP.request("GET", "http://localhost:$port//etc/passwd"; status_exception = false)
  #   @test req.status == (Sys.iswindows() ? 404 : 401)

  #   req = HTTP.request("GET", "http://localhost:$port/../../src/mimetypes.jl"; status_exception = false)
  #   @test req.status == 401

  #   Genie.Server.down!()
  #   server = nothing
  # end

  @testitem "serve_static_file does not serve unauthorised requests" setup=[GenieTestSetup] begin
    response = Genie.Router.serve_static_file("//etc/passwd", root = "public")
    @test response.status == 401

    response = Genie.Router.serve_static_file("../../../../etc/passwd", root = "public")
    @test response.status == 401
  end

# end
