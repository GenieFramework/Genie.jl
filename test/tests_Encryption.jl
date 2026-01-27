@safetestset "Encryption test" begin
  using Random
  using Genie.Secrets: secret_token!
  import Genie.Encryption: encrypt,decrypt

  secret_token!(repeat("f",64))

  function tamper_hex(s::String)
    v=collect(s)
    i=rand(1:length(v))
    hex=collect("0123456789abcdef")
    v[i]=rand(setdiff(hex,[v[i]]))
    String(v)
  end

  plain_texts=[
    "",
    "hello",
    "The quick brown fox jumps over the lazy dog",
    repeat("A",16),
    repeat("B",17),
    let n=rand(0:255)
      rand(UInt8,n)|>String
    end,
    rand(UInt8,1024)|>String,
  ]

  for pt in plain_texts
    ct=encrypt(pt)
    @test isa(ct,String)
    dt=decrypt(ct)
    @test dt==pt
  end

  x="constant"
  a=encrypt(x)
  b=encrypt(x)
  @test a!=b

  @test decrypt("ZZZ")==""
  @test decrypt("")==""

  ct=encrypt("safe")
  for _ in 1:10
    t=tamper_hex(ct)
    @test decrypt(t)==""
  end

  for L in (15,16,31,32,33)
    p=repeat('x',L)
    c=encrypt(p)
    @test decrypt(c)==p
  end

  for _ in 1:20
    junk=randstring(rand(0:64))
    @test decrypt(junk)==""
  end

  big=rand(UInt8,10_000)|>String
  cbig=encrypt(big)
  dbig=decrypt(cbig)
  @test dbig==big
end
