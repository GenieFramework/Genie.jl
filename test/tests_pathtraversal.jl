@safetestset "Path traversal" begin

  @safetestset "Returns 401 unauthorised" begin
    using Genie
    using HTTP

    isdir(Genie.config.server_document_root) || mkdir(Genie.config.server_document_root)

    port = rand(8000:10_000)
    server = up(port)

    req = HTTP.request("GET", "http://localhost:$port////etc/hosts"; status_exception = false)
    @test req.status == (Sys.iswindows() ? 404 : 401)

    req = HTTP.request("GET", "http://localhost:$port/../../src/mimetypes.jl"; status_exception = false)
    @test req.status == 401

    Genie.AppServer.down!()
    server = nothing
  end

  # Tests pass OK but for some reason some state remains and breaks next batch of tests... :-(
  # @safetestset "Authorised static server responses" begin
  #   using Genie
  #   using HTTP

  #   isdir(Genie.config.server_document_root) || mkdir(Genie.config.server_document_root)

  #   port = rand(8000:10_000)
  #   server = Genie.serve(; port)
  #   req = HTTP.request("GET", "http://localhost:$port//etc/passwd"; status_exception = false)
  #   @test req.status == (Sys.iswindows() ? 404 : 401)

  #   req = HTTP.request("GET", "http://localhost:$port/../../src/mimetypes.jl"; status_exception = false)
  #   @test req.status == 401

  #   down()
  #   sleep(1)
  #   server = nothing
  # end

  @safetestset "serve_static_file does not serve unauthorised requests" begin
    using Genie

    response = Genie.Router.serve_static_file("//etc/passwd", root = "public")
    @test response.status == (Sys.iswindows() ? 404 : 401)

    response = Genie.Router.serve_static_file("../../../../etc/passwd", root = "public")
    @test response.status == (Sys.iswindows() ? 404 : 401)
  end

end