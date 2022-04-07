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

end