@safetestset "No Caching" begin
  using Genie, Genie.Cache

  Cache.init()

  function f()
    rand(1:1_000)
  end

  Genie.config.cache_duration = 0 # no caching

  r0 = f()

  r1 = withcache(:x) do
    f()
  end

  @test r0 != r1 # because cache_duration == 0 so no caching

  r2 = withcache(:x) do
    f()
  end

  @test r1 != r2 # because cache_duration == 0 so no caching
end


@safetestset "cache" begin
  using Genie, Genie.Cache

  function f()
    rand(1:1_000)
  end

  Genie.config.cache_duration = 5

  r1 = withcache(:x) do
    f()
  end

  r2 = withcache(:x) do
    f()
  end

  @test r1 == r2

  r3 = withcache(:x, condition = false) do # disable caching cause !condition
    f()
  end

  @test r1 == r2 != r3

  r4 = withcache(:x, 0) do # disable caching with 0 duration
    f()
  end

  @test r1 == r2 != r3 != r4

  r5 = withcache(:x) do # regular cache should still work as under 5s passed
    f()
  end

  @test r1 == r2 == r5

  sleep(6)

  r6 = withcache(:x) do # regular cache should not work as over 5s passed
    f()
  end

  @test r1 == r2 == r5 != r6
end