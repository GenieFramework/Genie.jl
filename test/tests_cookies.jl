@testitem "Cookies with Encrypted Values" setup=[GenieTestSetup] begin

  using Genie, Genie.Cookies, Genie.Encryption, HTTP, Test

  # Set a temporary secret token for the encryption tests
  Genie.Secrets.secret_token!("repro-token-1234567890-1234567890")

  @testset "Cookie Retrieval with Quotes in Encrypted Value" begin
    # 1. Create a valid encrypted value
    data = "user-123"
    encrypted_value = Genie.Encryption.encrypt(data)

    # 2. Simulate the bug: wrap the value in quotes (reported Android behavior)
    value_with_quotes = "\"$encrypted_value\""

    # 3. Create a mocked HTTP request with the problematic Cookie header
    req = HTTP.Request("GET", "/", ["Cookie" => "my_session=$value_with_quotes"])

    # 4. Retrieve the cookie value using the nullablevalue function
    result = Genie.Cookies.get(req, "my_session", encrypted=true)

    @test result == data
  end

  @testset "Without Quotes in Encrypted Value" begin
    data = "user-456"
    encrypted_value = Genie.Encryption.encrypt(data)

    req = HTTP.Request("GET", "/", ["Cookie" => "my_session=$encrypted_value"])

    result = Genie.Cookies.get(req, "my_session", encrypted=true)

    @test result == data
  end

  @testset "Non-Encrypted Cookie Value" begin
    data = "plain-value"

    req = HTTP.Request("GET", "/", ["Cookie" => "my_session=$data"])

    result = Genie.Cookies.get(req, "my_session", encrypted=false)

    @test result == data
  end

  @testset "Double Quotes non-Encrypted Cookie Value" begin
    data = "plain-value-quoted"
    double_quoted_data = "\"$data\""

    req = HTTP.Request("GET", "/", ["Cookie" => "my_session=$double_quoted_data"])

    result = Genie.Cookies.get(req, "my_session", encrypted=false)

    @test result == data
  end

  @testset "Missing Cookie" begin
    req = HTTP.Request("GET", "/")

    result = Genie.Cookies.get(req, "non_existent_cookie", encrypted=true)

    @test result === nothing
  end

  @testset "Malformed Cookie Header" begin
    req = HTTP.Request("GET", "/", ["Cookie" => "malformed_cookie"])

    result = Genie.Cookies.get(req, "malformed_cookie", encrypted=true)

    @test result === ""
  end

  @testset "Empty Cookie Value" begin
    req = HTTP.Request("GET", "/", ["Cookie" => "empty_cookie="])

    result = Genie.Cookies.get(req, "empty_cookie", encrypted=true)

    @test result == ""
  end

  @testset "Multiple Cookies" begin
    data1 = "value1"
    data2 = "value2"
    encrypted_value2 = Genie.Encryption.encrypt(data2)

    req = HTTP.Request("GET", "/", ["Cookie" => "cookie1=$data1; cookie2=$encrypted_value2"])

    result1 = Genie.Cookies.get(req, "cookie1", encrypted=false)
    result2 = Genie.Cookies.get(req, "cookie2", encrypted=true)

    @test result1 == data1
    @test result2 == data2
  end

  @testset "Cookie Value with Special Characters" begin
    data = "value_with_special_chars_!@#\$%^&*()"
    encrypted_value = Genie.Encryption.encrypt(data)

    req = HTTP.Request("GET", "/", ["Cookie" => "special_cookie=$encrypted_value"])

    result = Genie.Cookies.get(req, "special_cookie", encrypted=true)

    @test result == data
  end

  @testset "Cookie Name Case Insensitivity" begin
    data = "case-test"
    encrypted_value = Genie.Encryption.encrypt(data)

    req = HTTP.Request("GET", "/", ["Cookie" => "MY_SESSION=$encrypted_value"])

    result = Genie.Cookies.get(req, "my_session", encrypted=true)

    @test result == data
  end
 

  @testset "Whitespace Handling in Cookie Value" begin
    data = "whitespace-test"
    encrypted_value = Genie.Encryption.encrypt(data)

    req = HTTP.Request("GET", "/", ["Cookie" => "spaced_cookie = $encrypted_value "])

    # The cookie parsing may be affected by spaces; this tests robustness
    result = Genie.Cookies.get(req, "spaced_cookie", encrypted=true)

    @test result == data
  end

  @testset "Cookie Value is Just Quotes" begin
    req = HTTP.Request("GET", "/", ["Cookie" => "empty_quoted=\"\""])

    result = Genie.Cookies.get(req, "empty_quoted", encrypted=false)

    @test result == ""
  end

  @testset "Very Large Cookie Value" begin
    data = "a"^5000  # 5000 characters
    encrypted_value = Genie.Encryption.encrypt(data)

    req = HTTP.Request("GET", "/", ["Cookie" => "large_cookie=$encrypted_value"])

    result = Genie.Cookies.get(req, "large_cookie", encrypted=true)

    @test result == nothing
  end


  # Regression tests: Genie.Cookies.get(::HTTP.Response, key) used to always return
  # `nothing`, regardless of whether the cookie was actually set. Root cause: Dict(payload)
  # dispatches to Genie.HTTPUtils.Dict(req::HTTP.Request) for a Request (more specific than
  # Cookies' own Union{Request,Response} method), which returns {"cookie" => "<raw value>"}
  # as expected -- but HTTPUtils only defines that method for Request, not Response, so for
  # a Response the only applicable Dict method was Cookies' own, returning
  # {cookie_name => value} pairs instead, so `Dict(payload)["cookie"]` never matched.

  @testset "Cookie Retrieval from a Response (single cookie)" begin
    res = HTTP.Response(200)
    Genie.Cookies.set!(res, "my_session", "hello-response"; encrypted = false)

    @test Genie.Cookies.get(res, "my_session", encrypted = false) == "hello-response"
    @test Genie.Cookies.get(res, "nonexistent", encrypted = false) === nothing
  end

  @testset "Cookie Retrieval from a Response (multiple Set-Cookie headers)" begin
    # A response can carry more than one Set-Cookie header, one per cookie -- this must
    # not collapse to only the last one being readable.
    res = HTTP.Response(200)
    Genie.Cookies.set!(res, "a", "1"; encrypted = false)
    Genie.Cookies.set!(res, "b", "2"; encrypted = false)

    @test length([h for h in res.headers if h.first == "Set-Cookie"]) == 2
    @test Genie.Cookies.get(res, "a", encrypted = false) == "1"
    @test Genie.Cookies.get(res, "b", encrypted = false) == "2"
  end

  @testset "Dict(res) aggregates across multiple Set-Cookie headers" begin
    res = HTTP.Response(200)
    Genie.Cookies.set!(res, "a", "1"; encrypted = false)
    Genie.Cookies.set!(res, "b", "2"; encrypted = false)

    @test Dict(res) == Dict("a" => "1", "b" => "2")
  end

  @testset "Cookie attributes (Path, HttpOnly) on a Response don't interfere" begin
    res = HTTP.Response(200)
    Genie.Cookies.set!(res, "sess", "xyz", Dict("path" => "/", "httponly" => true); encrypted = false)

    @test Genie.Cookies.get(res, "sess", encrypted = false) == "xyz"
  end

  @testset "Encrypted cookie round-trip on a Response" begin
    data = "secret-response-value"
    res = HTTP.Response(200)
    Genie.Cookies.set!(res, "enc", data; encrypted = true)

    @test Genie.Cookies.get(res, "enc", encrypted = true) == data
  end

  @testset "Response with no Set-Cookie header at all" begin
    res = HTTP.Response(200)

    @test Genie.Cookies.get(res, "anything", encrypted = false) === nothing
  end

end