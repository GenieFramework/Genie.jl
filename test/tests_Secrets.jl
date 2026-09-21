@safetestset "Genie.Secrets" begin
  import Genie
  import Genie.Secrets:
      secret,
      secret_token!,
      secret_token,
      secret_file_exists,
      secret_file_path,
      load as load_secrets

  # 1) secret() returns 64 hex chars
  t1=secret()
  @test length(t1)==64
  @test occursin(r"^[0-9a-f]{64}$", t1)

  # 2) set and get with secret_token!
  tok=repeat("f",64)
  secret_token!(tok)
  @test secret_token(false)==tok
  @test secret_token()==tok

  # 3) Write a real config/secrets.jl in a temp dir
  tmp=mktempdir()
  cfg=joinpath(tmp,"config")
  mkpath(cfg)
  f=joinpath(cfg,"secrets.jl")
  open(f,"w") do io
    println(io,"Genie.Secrets.secret_token!(\"$tok\")")
  end

  @test secret_file_exists(cfg)
  @test endswith(secret_file_path(cfg),"secrets.jl")

  # 4) Load it by passing the absolute config dir
  old=repeat("0",64)
  secret_token!(old)
  @test secret_token(false)==old
  @test load_secrets(cfg)===nothing
  @test secret_token(false)==tok
end
