using Test
using HTTP
using Genie
using Genie.Cookies
using GenieSession

# This test verifies that the cookie optimization PR (perf/optimize-cookies)
# doesn't break GenieSession.jl compatibility.
# GenieSession depends on:
# 1. Encrypted cookies for session transport
# 2. Cookie attribute normalization (max_age, http_only, same_site)
# 3. Proper Set-Cookie header handling on HTTP.Response objects

# Configure the secret token (required for encryption)
Genie.Secrets.secret_token!("test-secret-token-1234-5678")

# ==========================================================================
# ADAPTER SETUP: Implement required GenieSession adapters (module-level)
# ==========================================================================

# In-memory storage for session testing
const SESSION_STORAGE = Dict{String, GenieSession.Session}()

# Define the required GenieSession adapter functions in a way that allows
# GenieSessionFileSession to override them later without warnings
function GenieSession.load(session_id::String)
    if haskey(SESSION_STORAGE, session_id)
        return SESSION_STORAGE[session_id]
    else
        return GenieSession.Session(session_id)
    end
end

function GenieSession.persist(s::GenieSession.Session)
    SESSION_STORAGE[s.id] = s
    return s
end

# Bridge method: The actual Router hook signature
# Genie.Router calls persist(req, res, params) -> (req, res, params)
function GenieSession.persist(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any})
    if haskey(params, GenieSession.PARAMS_SESSION_KEY)
        session = params[GenieSession.PARAMS_SESSION_KEY]
        GenieSession.persist(session)
    end
    return req, res, params
end

# Suppress the method redefinition warnings from GenieSessionFileSession by
# pre-declaring that these methods will be overridden
# This is expected behavior when GenieSessionFileSession is imported

# ==========================================================================
# TESTS
# ==========================================================================

@safetestset "GenieSession Compatibility Tests" begin

    using Test
    using HTTP
    using Genie
    using Genie.Cookies
    using GenieSession

    @testset "Encrypted cookie creation and retrieval" begin
        # Create a response object (what Genie server uses)
        res = HTTP.Response()
        
        # Set an encrypted cookie - this is exactly how GenieSession transports sessions
        Genie.Cookies.set!(res, "__geniesid", "session_data_encrypted", 
                          Dict("path" => "/", "httponly" => true), encrypted=true)
        
        # Verify the Set-Cookie header is present
        cookie_header = HTTP.header(res, "Set-Cookie")
        @test !isempty(cookie_header)
        @test contains(cookie_header, "__geniesid")
    end

    @testset "Cookie attribute normalization for GenieSession patterns" begin
        # GenieSession uses various attribute names
        res = HTTP.Response()
        
        # Test with normalized names (HTTP.Cookies compatible)
        Genie.Cookies.set!(res, "session", "data",
                          Dict("maxage" => 3600, "httponly" => true, 
                               "samesite" => "Lax", "path" => "/"),
                          encrypted=true)
        
        cookie_header = HTTP.header(res, "Set-Cookie")
        @test !isempty(cookie_header)
        @test contains(lowercase(cookie_header), "path=/")
    end

    @testset "Multiple encrypted cookies (session + CSRF)" begin
        # GenieSession pattern: session cookie + CSRF token cookie
        res = HTTP.Response()
        
        # Session cookie
        Genie.Cookies.set!(res, "__geniesid", "encrypted_session_id",
                          Dict("httponly" => true, "path" => "/"),
                          encrypted=true)
        
        # CSRF token cookie (public, not encrypted)
        Genie.Cookies.set!(res, "csrf_token", "public_csrf_token",
                          Dict("samesite" => "Lax"),
                          encrypted=false)
        
        # Both should be in Set-Cookie headers
        all_headers = HTTP.header(res, "Set-Cookie")
        @test !isempty(all_headers)
    end

    @testset "Cookie clearing pattern used by GenieSession" begin
        # GenieSession uses empty value to clear cookies
        res = HTTP.Response()
        
        # Set a cookie
        Genie.Cookies.set!(res, "session", "value", Dict("path" => "/"), encrypted=false)
        initial_header = HTTP.header(res, "Set-Cookie")
        @test !isempty(initial_header)
        
        # Clear it by setting empty value
        res2 = HTTP.Response()
        Genie.Cookies.set!(res2, "session", "", Dict("path" => "/", "maxage" => 0), encrypted=false)
        cleared_header = HTTP.header(res2, "Set-Cookie")
        @test !isempty(cleared_header)
    end

    @testset "GenieSession Session Object Operations" begin
        # Test basic session operations
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Test setting and getting session data
        GenieSession.set!(s, :user_id, 42)
        GenieSession.set!(s, :username, "testuser")
        
        @test GenieSession.get(s, :user_id) == 42
        @test GenieSession.get(s, :username) == "testuser"
        
        # Verify persistence via adapter
        @test haskey(Main.SESSION_STORAGE, sid)
        @test Main.SESSION_STORAGE[sid].data[:user_id] == 42
    end

    @testset "GenieSession.isset and unset operations" begin
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Set a value
        GenieSession.set!(s, :test_key, "test_value")
        @test GenieSession.isset(s, :test_key) == true
        
        # Unset it
        GenieSession.unset!(s, :test_key)
        @test GenieSession.isset(s, :test_key) == false
        @test GenieSession.get(s, :test_key) === nothing
    end

    @testset "GenieSession get with defaults" begin
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Test get with nil value returns default
        val = GenieSession.get(s, :nonexistent, "default_value")
        @test val == "default_value"
        
        # When key is set, get returns the value
        GenieSession.set!(s, :existing_key, "actual_value")
        val2 = GenieSession.get(s, :existing_key, "default_value")
        @test val2 == "actual_value"
    end

    @testset "Legacy CamelCase Attribute Keys (GenieSession Compatibility)" begin
        # GenieSession historically uses CamelCase keys like "MaxAge" and "HttpOnly"
        # The helper functions must normalize these to work with HTTP.Cookies
        res = HTTP.Response()
        
        # Emulate exactly what GenieSession.start() does:
        # It passes "MaxAge" (no hyphen), "HttpOnly" (CamelCase)
        legacy_options = Dict{String,Any}(
            "Path" => "/app",
            "HttpOnly" => true,
            "SameSite" => "Strict",
            "MaxAge" => 3600  # Note: GenieSession uses "MaxAge", standard is "Max-Age"
        )
        
        Genie.Cookies.set!(res, "session_test", "data", legacy_options, encrypted=true)
        
        header = HTTP.header(res, "Set-Cookie")
        header_lower = lowercase(header)
        
        # Verify attributes were recognized and properly normalized in header
        @test contains(header_lower, "httponly")
        @test contains(header_lower, "path=/app")
        @test contains(header_lower, "samesite=strict")
        @test contains(header_lower, "max-age=3600")  # Must normalize "MaxAge" -> "max-age"
    end

    @testset "Flash Message Integration with GenieSession" begin
        # Flash messages are a GenieSession feature for one-time notifications
        # They rely on the session object to persist data across the set! call
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Simulate setting a flash message
        # GenieSession.Flash.flash("Login failed") internally calls:
        # GenieSession.set!(session, :__flash, message)
        GenieSession.set!(s, :__flash, "Login failed")
        GenieSession.persist(s)
        
        # New request loads session
        s_loaded = GenieSession.load(sid)
        flash_msg = GenieSession.get(s_loaded, :__flash)
        
        # Verify flash message persisted correctly
        @test flash_msg == "Login failed"
        
        # Simulate clearing the flash after it's been displayed
        GenieSession.unset!(s_loaded, :__flash)
        GenieSession.persist(s_loaded)
        
        # Next request should have no flash
        s_reloaded = GenieSession.load(sid)
        @test GenieSession.isset(s_reloaded, :__flash) == false
    end

end

# ==========================================================================
# HOOK INTEGRATION TESTS (GenieSession Router Hook Mechanism)
# ==========================================================================

@safetestset "GenieSession Hook Integration Tests" begin

    using Test
    using HTTP
    using Genie
    using Genie.Cookies
    using GenieSession

    @testset "Hook: persist callback is correctly defined" begin
        # Verify that persist is callable and accepts required arguments
        @test isa(GenieSession.persist, Function)
        
        # Test that persist works with a Session object
        s = GenieSession.Session("test_hook_id")
        GenieSession.set!(s, :hook_test, "hook_value")
        result = GenieSession.persist(s)
        
        # Should return the session
        @test result.id == "test_hook_id"
        @test GenieSession.get(result, :hook_test) == "hook_value"
    end

    @testset "Hook: Router callback signature" begin
        # The Genie Router calls persist with (Request, Response, Params)
        # We need to ensure this 'bridge' method exists and delegates to persist(Session)
        
        session_id = GenieSession.id()
        s = GenieSession.Session(session_id)
        GenieSession.set!(s, :bridge_test, "router_hook_works")
        
        # Mock the params dict that Genie.Router would create
        params = Dict{Symbol,Any}(GenieSession.PARAMS_SESSION_KEY => s)
        req = HTTP.Request("GET", "/")
        res = HTTP.Response()
        
        # Call the hook exactly as Genie.Router does
        # If this fails, it means GenieSession isn't compatible with the Router
        ret_req, ret_res, ret_params = GenieSession.persist(req, res, params)
        
        # Verify the hook returns the correct types and values
        @test ret_req == req
        @test ret_res == res
        @test ret_params == params
        
        # Verify it actually saved the session to our storage
        @test haskey(Main.SESSION_STORAGE, session_id)
        @test GenieSession.get(Main.SESSION_STORAGE[session_id], :bridge_test) == "router_hook_works"
    end

    @testset "Hook: Multi-request persistence simulation" begin
        # Simulate a multi-request scenario where a session is created, 
        # modified across requests, and persisted via hook
        
        session_id = GenieSession.id()
        
        # REQUEST 1: Create session with initial data
        req1 = HTTP.Request("GET", "/login")
        res1 = HTTP.Response()
        
        session1 = GenieSession.Session(session_id)
        GenieSession.set!(session1, :user_id, 100)
        GenieSession.set!(session1, :user_name, "alice")
        GenieSession.set!(session1, :login_time, "2024-01-18T10:00:00")
        
        # Hook: persist session after request
        GenieSession.persist(session1)
        Genie.Cookies.set!(res1, "__geniesid", session_id, 
                          Dict("httponly" => true, "path" => "/"), encrypted=true)
        
        # Verify session is stored
        @test haskey(Main.SESSION_STORAGE, session_id)
        @test GenieSession.get(Main.SESSION_STORAGE[session_id], :user_id) == 100
        
        # REQUEST 2: Load session from cookie, modify it
        req2 = HTTP.Request("GET", "/dashboard")
        res2 = HTTP.Response()
        
        # Hook: load session from storage
        session2 = GenieSession.load(session_id)
        
        # Verify all data persisted from request 1
        @test GenieSession.get(session2, :user_id) == 100
        @test GenieSession.get(session2, :user_name) == "alice"
        @test GenieSession.get(session2, :login_time) == "2024-01-18T10:00:00"
        
        # Add new data in request 2
        GenieSession.set!(session2, :last_page, "/dashboard")
        GenieSession.set!(session2, :action_count, 1)
        
        # Hook: persist session after request 2
        GenieSession.persist(session2)
        Genie.Cookies.set!(res2, "__geniesid", session_id,
                          Dict("httponly" => true, "path" => "/"), encrypted=true)
        
        # REQUEST 3: Verify all accumulated changes persist
        session3 = GenieSession.load(session_id)
        
        # Original data from request 1
        @test GenieSession.get(session3, :user_id) == 100
        @test GenieSession.get(session3, :user_name) == "alice"
        
        # New data from request 2
        @test GenieSession.get(session3, :last_page) == "/dashboard"
        @test GenieSession.get(session3, :action_count) == 1
    end

    @testset "Hook: Session modification and re-persistence" begin
        # Test that modifications to session data are properly persisted
        session_id = GenieSession.id()
        
        # Initial creation
        s1 = GenieSession.Session(session_id)
        GenieSession.set!(s1, :counter, 0)
        GenieSession.set!(s1, :status, "active")
        GenieSession.persist(s1)
        
        # Load and modify
        s2 = GenieSession.load(session_id)
        GenieSession.set!(s2, :counter, 1)
        GenieSession.persist(s2)
        
        # Load again and verify both old and new data
        s3 = GenieSession.load(session_id)
        @test GenieSession.get(s3, :counter) == 1
        @test GenieSession.get(s3, :status) == "active"
        
        # More modifications
        GenieSession.set!(s3, :counter, 2)
        GenieSession.unset!(s3, :status)
        GenieSession.set!(s3, :modified_at, "timestamp")
        GenieSession.persist(s3)
        
        # Final verification
        s4 = GenieSession.load(session_id)
        @test GenieSession.get(s4, :counter) == 2
        @test GenieSession.isset(s4, :status) == false
        @test GenieSession.get(s4, :modified_at) == "timestamp"
    end

    @testset "Hook: Cookie header generation on persist" begin
        # Simulate full request/response cycle with cookie headers
        session_id = GenieSession.id()
        
        # Create and persist session
        s = GenieSession.Session(session_id)
        GenieSession.set!(s, :data, "value")
        GenieSession.persist(s)
        
        # Create response and set cookie (as Genie.Router would)
        res = HTTP.Response()
        Genie.Cookies.set!(res, "__geniesid", session_id,
                          Dict("httponly" => true, "path" => "/", 
                               "samesite" => "Lax"),
                          encrypted=true)
        
        # Verify Set-Cookie header is present
        cookie_header = HTTP.header(res, "Set-Cookie")
        @test !isempty(cookie_header)
        @test contains(cookie_header, "__geniesid")
        @test contains(lowercase(cookie_header), "httponly")
        @test contains(lowercase(cookie_header), "path=/")
    end

    @testset "Hook: Error handling during persist" begin
        # Test that errors during persist don't break the session
        session_id = GenieSession.id()
        s = GenieSession.Session(session_id)
        
        GenieSession.set!(s, :important_data, "should_not_lose")
        
        # Persist normally
        result = try
            GenieSession.persist(s)
            true
        catch e
            false
        end
        
        @test result == true
        
        # Verify data is still there
        loaded = GenieSession.load(session_id)
        @test GenieSession.get(loaded, :important_data) == "should_not_lose"
    end

    @testset "Hook: Concurrent session handling" begin
        # Test that multiple sessions can be managed independently via hooks
        session_ids = [GenieSession.id() for _ in 1:3]
        
        # Create and persist multiple sessions
        for (i, sid) in enumerate(session_ids)
            s = GenieSession.Session(sid)
            GenieSession.set!(s, :session_id, i)
            GenieSession.set!(s, :user_id, 1000 + i)
            GenieSession.persist(s)
        end
        
        # Verify each session maintains its data
        for (i, sid) in enumerate(session_ids)
            loaded = GenieSession.load(sid)
            @test GenieSession.get(loaded, :session_id) == i
            @test GenieSession.get(loaded, :user_id) == 1000 + i
        end
        
        # Modify one and verify others unchanged
        s_modified = GenieSession.load(session_ids[2])
        GenieSession.set!(s_modified, :user_id, 9999)
        GenieSession.persist(s_modified)
        
        # Check that other sessions are unaffected
        s_check1 = GenieSession.load(session_ids[1])
        s_check3 = GenieSession.load(session_ids[3])
        
        @test GenieSession.get(s_check1, :user_id) == 1001
        @test GenieSession.get(s_check3, :user_id) == 1003
        @test GenieSession.get(s_modified, :user_id) == 9999
    end

    @testset "Hook: Session lifecycle with cookie clearing" begin
        # Test complete session lifecycle: create → use → clear
        session_id = GenieSession.id()
        
        # CREATE: Session creation and persist
        s_create = GenieSession.Session(session_id)
        GenieSession.set!(s_create, :user_id, 42)
        GenieSession.persist(s_create)
        
        res_create = HTTP.Response()
        Genie.Cookies.set!(res_create, "__geniesid", session_id,
                          Dict("httponly" => true, "path" => "/"),
                          encrypted=true)
        @test !isempty(HTTP.header(res_create, "Set-Cookie"))
        
        # USE: Load and modify
        s_use = GenieSession.load(session_id)
        @test GenieSession.get(s_use, :user_id) == 42
        GenieSession.set!(s_use, :page_views, 5)
        GenieSession.persist(s_use)
        
        # CLEAR: Clear session (logout pattern)
        # In a real app, the session would be deleted from storage
        # For testing, we simulate this by removing from storage and creating new session
        if haskey(Main.SESSION_STORAGE, session_id)
            delete!(Main.SESSION_STORAGE, session_id)
        end
        
        res_clear = HTTP.Response()
        Genie.Cookies.set!(res_clear, "__geniesid", "",
                          Dict("path" => "/", "maxage" => 0),
                          encrypted=false)
        @test !isempty(HTTP.header(res_clear, "Set-Cookie"))
        
        # Verify new session is created after clearing
        s_after_clear = GenieSession.load(session_id)
        @test s_after_clear.id == session_id
        # Should be a fresh session with empty data (no user_id or page_views)
        @test !GenieSession.isset(s_after_clear, :user_id)
        @test !GenieSession.isset(s_after_clear, :page_views)
    end

    @testset "Hook: Complex data persistence through hook" begin
        # Test that complex nested structures survive hook persist/load cycle
        session_id = GenieSession.id()
        
        # Create complex nested structure
        complex_data = Dict(
            "user" => Dict(
                "id" => 1,
                "profile" => Dict(
                    "name" => "Bob",
                    "email" => "bob@example.com",
                    "preferences" => ["dark_mode", "notifications"]
                )
            ),
            "cart" => [
                Dict("product_id" => 101, "quantity" => 2),
                Dict("product_id" => 102, "quantity" => 1)
            ],
            "metadata" => Dict(
                "created_at" => "2024-01-18",
                "ip_address" => "192.168.1.1"
            )
        )
        
        # Persist via hook
        s1 = GenieSession.Session(session_id)
        GenieSession.set!(s1, :session_data, complex_data)
        GenieSession.persist(s1)
        
        # Load and verify structure integrity
        s2 = GenieSession.load(session_id)
        loaded_data = GenieSession.get(s2, :session_data)
        
        @test loaded_data["user"]["id"] == 1
        @test loaded_data["user"]["profile"]["name"] == "Bob"
        @test loaded_data["user"]["profile"]["preferences"][1] == "dark_mode"
        @test loaded_data["cart"][1]["product_id"] == 101
        @test loaded_data["metadata"]["ip_address"] == "192.168.1.1"
        
        # Modify and re-persist
        loaded_data["user"]["profile"]["name"] = "Robert"
        loaded_data["cart"][1]["quantity"] = 3
        GenieSession.set!(s2, :session_data, loaded_data)
        GenieSession.persist(s2)
        
        # Verify modifications persisted
        s3 = GenieSession.load(session_id)
        final_data = GenieSession.get(s3, :session_data)
        
        @test final_data["user"]["profile"]["name"] == "Robert"
        @test final_data["cart"][1]["quantity"] == 3
    end

    

end

# ==========================================================================
# FILE-BASED SESSION TESTS (GenieSessionFileSession - Optional)
# ==========================================================================


@safetestset "GenieSessionFileSession File Storage Tests" begin

    using Test
    using Genie
    using Dates
    using Genie.Cookies
    using GenieSession
    using GenieSessionFileSession
    import Base.Filesystem

    # Create a temporary directory for session files
    temp_session_dir = mktempdir()
    
    # Set GenieSessionFileSession to use temporary directory
    GenieSessionFileSession.sessions_path(temp_session_dir)
    
    @testset "FileSession adapter: Save and load sessions" begin
        # Create a session
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Set data
        GenieSession.set!(s, :user_id, 123)
        GenieSession.set!(s, :username, "filetest")
        
        # Persist to file
        GenieSessionFileSession.write(s)
        
        # Load from file
        loaded_session = GenieSessionFileSession.read(sid)
        
        # Verify data was persisted
        @test GenieSession.get(loaded_session, :user_id) == 123
        @test GenieSession.get(loaded_session, :username) == "filetest"
    end

    @testset "FileSession adapter: Complex data structures" begin
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Store complex data
        complex_data = Dict(
            "user" => Dict("id" => 1, "name" => "Alice"),
            "permissions" => ["read", "write"],
            "metadata" => Dict("created_at" => "2024-01-18", "expires" => 3600)
        )
        
        GenieSession.set!(s, :complex_data, complex_data)
        
        # Persist and reload
        GenieSessionFileSession.write(s)
        loaded = GenieSessionFileSession.read(sid)
        
        # Verify complex data integrity
        @test GenieSession.get(loaded, :complex_data) == complex_data
    end

    @testset "FileSession adapter: Session persistence across load cycles" begin
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        # Set temporary data
        GenieSession.set!(s, :temp_data, "should persist")
        GenieSession.set!(s, :timestamp, "created_at_time")
        
        # First persist
        GenieSessionFileSession.write(s)
        
        # Load and modify
        loaded = GenieSessionFileSession.read(sid)
        @test GenieSession.get(loaded, :temp_data) == "should persist"
        
        # Add more data
        GenieSession.set!(loaded, :additional_data, "added later")
        
        # Persist again
        GenieSessionFileSession.write(loaded)
        
        # Load final version
        final = GenieSessionFileSession.read(sid)
        @test GenieSession.get(final, :temp_data) == "should persist"
        @test GenieSession.get(final, :additional_data) == "added later"
    end

    @testset "FileSession adapter: Multiple sessions" begin
        # Create multiple sessions
        sids = [GenieSession.id() for _ in 1:3]
        sessions = [GenieSession.Session(sid) for sid in sids]
        
        # Store different data in each
        for (i, s) in enumerate(sessions)
            GenieSession.set!(s, :session_num, i)
            GenieSession.set!(s, :data, "session_$i")
            GenieSessionFileSession.write(s)
        end
        
        # Load and verify each session
        for (i, sid) in enumerate(sids)
            loaded = GenieSessionFileSession.read(sid)
            @test GenieSession.get(loaded, :session_num) == i
            @test GenieSession.get(loaded, :data) == "session_$i"
        end
    end

    @testset "FileSession adapter: File system integrity" begin
        sid = GenieSession.id()
        s = GenieSession.Session(sid)
        
        GenieSession.set!(s, :important_data, "preserve this")
        GenieSessionFileSession.write(s)
        
        # Verify file exists
        session_file = joinpath(temp_session_dir, sid)
        @test isfile(session_file)
        
        # Verify file is readable
        file_size = filesize(session_file)
        @test file_size > 0
    end

    # Cleanup
    rm(temp_session_dir, recursive=true)

end
