@safetestset "Path traversal" begin
  using Genie
  tmp_public=mktempdir()
  old_public=Genie.config.server_document_root
  Genie.config.server_document_root=tmp_public

  @testset "Via HTTP.request (200/404 only)" begin
    using Genie, HTTP
    isdir(Genie.config.server_document_root) || mkpath(Genie.config.server_document_root)
    port=rand(8000:10000)
    task=@async Genie.up(port; verbose=false)
    sleep(0.05)
    try
      write(joinpath(Genie.config.server_document_root,"hi.txt"),"ok")
      r1=HTTP.get("http://localhost:$port/hi.txt")
      @test r1.status==200
      r2=HTTP.get("http://localhost:$port/../hi.txt"; status_exception=false)
      @test r2.status==404
      r3=HTTP.get("http://localhost:$port/%2e%2e/hi.txt"; status_exception=false)
      @test r3.status==404
      r4=HTTP.get("http://localhost:$port/nope"; status_exception=false)
      @test r4.status==404
    finally
      Genie.down!()
      sleep(0.05)
    end
  end

  @testset "Direct serve_static_file (200/403/404)" begin
    using Genie, HTTP
    resp1=Genie.Router.serve_static_file("/hi.txt";
      root=Genie.config.server_document_root)
    @test resp1.status==200
    resp2=Genie.Router.serve_static_file("/../hi.txt";
      root=Genie.config.server_document_root)
    @test resp2.status==403
    resp3=Genie.Router.serve_static_file("/%2e%2e/hi.txt";
      root=Genie.config.server_document_root)
    @test resp3.status==403
    resp4=Genie.Router.serve_static_file("/does-not-exist";
      root=Genie.config.server_document_root)
    @test resp4.status==404
  end

  Genie.config.server_document_root=old_public
  rm(tmp_public; force=true, recursive=true)
end

@safetestset "serve_static_file edge‐cases" begin
  using HTTP, Genie
  import Genie.Router: serve_static_file
  import HTTP: header
  get_header=header
  root=mktempdir()
  write(joinpath(root,"hello.txt"),"world")
  mkpath(joinpath(root,"blog"))
  write(joinpath(root,"blog","index.html"),"<h1>Blog</h1>")
  outside=mktempdir()
  write(joinpath(outside,"secret.txt"),"TOP SECRET")
  symlink(joinpath(outside,"secret.txt"), joinpath(root,"link_secret.txt"))

  @testset "good paths" begin
    r=serve_static_file("/hello.txt"; root=root)
    @test r.status==200
    @test String(r.body)=="world"
    @test occursin("text/plain", get_header(r, "Content-Type"))
    rdl=serve_static_file("/hello.txt"; root=root, download=true)
    @test occursin("attachment; filename=hello.txt",
      get_header(rdl, "Content-Disposition"))
    rd=serve_static_file("/blog"; root=root)
    @test rd.status==200
    @test occursin("<h1>Blog</h1>", String(rd.body))
    r2=serve_static_file("///hello.txt"; root=root)
    @test r2.status==200
    rq=serve_static_file("/hello.txt?foo=bar"; root=root)
    @test rq.status==200
  end

  @testset "forbid literal ../ in the request path" begin
    for bad in ("/../hello.txt", "/blog/../../hello.txt", "//..//..//etc/passwd")
      resp=serve_static_file(bad; root=root)
      @test resp.status==403
    end
    if Sys.iswindows()
      resp=serve_static_file(raw"blog\..\hello.txt"; root=root)
      @test resp.status==403
    end
  end

  @testset "forbid symlink pointing outside" begin
    resp=serve_static_file("/link_secret.txt"; root=root)
    @test resp.status==403
  end

  @testset "forbid nested‐symlink pointing outside" begin
    symlink(outside, joinpath(root,"foo"))
    resp=serve_static_file("/foo/secret.txt"; root=root)
    @test resp.status==403
    @test !occursin("TOP SECRET", String(resp.body))
  end

  @testset "missing files yield 404" begin
    rnf=serve_static_file("/this-does-not-exist.txt"; root=root)
    @test rnf.status==404
    mkpath(joinpath(root,"emptydir"))
    rd2=serve_static_file("/emptydir"; root=root)
    @test rd2.status==404
  end
end
