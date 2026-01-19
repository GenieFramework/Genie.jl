# Working with Sessions

Sessions are a crucial part of web application development, allowing you to maintain state across multiple requests from the same user. Genie provides comprehensive session management through the **GenieSession.jl** plugin, which builds on Genie's encrypted cookie infrastructure.

## What are Sessions?

A **session** is a way to store user-specific data on the server and maintain it across multiple HTTP requests. Unlike cookies, which are stored on the client, sessions keep data secure on the server and use encrypted cookies only as a transport mechanism.

### Sessions vs Cookies

| Aspect | Cookies | Sessions |
|--------|---------|----------|
| **Storage** | Client-side browser | Server-side storage |
| **Security** | Limited (can be encrypted) | High (data never leaves server) |
| **Size** | ~4KB limit | Unlimited (limited by storage) |
| **Data Type** | Strings | Any Julia object |
| **Use Case** | Preferences, tracking | User auth, sensitive data |

### How Sessions Work in Genie

1. User data is stored in a session object on the server
2. A unique session ID is generated
3. The session ID is encrypted and sent to the client as a cookie
4. On subsequent requests, the client sends the encrypted session ID
5. Genie decrypts the ID and retrieves the session from storage
6. After the request completes, the session is persisted back to storage

## Getting Started with GenieSession

### Installation

GenieSession is added to your Genie app's test dependencies by default. To use it in your app:

```julia
using Pkg
Pkg.add("GenieSession")
```

### Basic Configuration

In your Genie app, GenieSession requires:

1. **A secret token** for encryption:
```julia
# config/secrets.jl or config/env/production.jl
Genie.Secrets.secret_token!("your-long-random-secret-key-here")
```

2. **A storage adapter** (file-based by default):
```julia
# Import GenieSession to activate its default adapter
using GenieSession
```

For file-based persistent storage:
```julia
using GenieSession
using GenieSessionFileSession
```

## Session Basics

### Setting Session Data

```julia
using GenieSession

# Get the current session (created if it doesn't exist)
session = Genie.Router.params(:session)

# Set session data
GenieSession.set!(session, :user_id, 42)
GenieSession.set!(session, :username, "alice")
GenieSession.set!(session, :preferences, Dict("theme" => "dark"))
```

### Retrieving Session Data

```julia
# Get a value
user_id = GenieSession.get(session, :user_id)  # Returns 42

# Get with a default value
theme = GenieSession.get(session, :theme, "light")  # Returns "light" if not set

# Check if a key exists
if GenieSession.isset(session, :user_id)
    println("User is logged in")
end
```

### Modifying and Removing Data

```julia
# Update a value
GenieSession.set!(session, :page_views, 5)
GenieSession.set!(session, :page_views, 6)  # Overwrites previous value

# Remove a value
GenieSession.unset!(session, :preferences)

# Check after removal
GenieSession.isset(session, :preferences)  # Returns false
```

## Working with Complex Data

Sessions can store any Julia object, making them perfect for complex data structures:

```julia
# Store nested structures
user_data = Dict(
    "id" => 1,
    "profile" => Dict(
        "name" => "Alice",
        "email" => "alice@example.com",
        "preferences" => ["dark_mode", "notifications"]
    )
)

GenieSession.set!(session, :user_data, user_data)

# Retrieve and access
data = GenieSession.get(session, :user_data)
println(data["profile"]["name"])  # "Alice"

# Store collections
cart = [
    Dict("product_id" => 101, "quantity" => 2),
    Dict("product_id" => 102, "quantity" => 1)
]

GenieSession.set!(session, :cart, cart)
```

## Session Storage Adapters

GenieSession's power comes from its pluggable adapter system. Different adapters allow you to store sessions in different places.

### In-Memory Sessions (Development)

Perfect for development and testing:

```julia
# Default in-memory storage
using GenieSession
```

**Pros:**
- Fast (no I/O)
- Perfect for testing
- No dependencies

**Cons:**
- Sessions lost on server restart
- Not suitable for production
- Single-server only

### File-Based Sessions (Production)

For persistent, scalable storage:

```julia
using GenieSession
using GenieSessionFileSession

# Configure storage location (optional)
GenieSessionFileSession.sessions_path("/var/sessions")
```

**Pros:**
- Persistent across restarts
- Works across multiple servers (with shared filesystem)
- No database required

**Cons:**
- Slower than in-memory
- Requires filesystem access
- Not suitable for distributed setups without shared storage

### Implementing Custom Adapters

You can implement your own adapter by defining two functions:

```julia
# Load a session from your storage backend
function GenieSession.load(session_id::String) :: GenieSession.Session
    # Try to load from your storage
    # If not found, return a new session
    if session_in_storage(session_id)
        return retrieve_from_storage(session_id)
    else
        return GenieSession.Session(session_id)
    end
end

# Persist a session to your storage backend
function GenieSession.persist(s::GenieSession.Session) :: GenieSession.Session
    # Save the session to your storage
    save_to_storage(s)
    return s
end

# Router hook signature (for Genie.Router integration)
function GenieSession.persist(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any})
    if haskey(params, GenieSession.PARAMS_SESSION_KEY)
        session = params[GenieSession.PARAMS_SESSION_KEY]
        GenieSession.persist(session)
    end
    return req, res, params
end
```

Example: Database Adapter

```julia
using SearchLight

function GenieSession.load(session_id::String) :: GenieSession.Session
    session_data = SessionModel |> (s -> s.id == session_id) |> findone
    
    if session_data !== nothing
        # Deserialize data from database
        return GenieSession.Session(session_id, session_data.data)
    else
        return GenieSession.Session(session_id)
    end
end

function GenieSession.persist(s::GenieSession.Session) :: GenieSession.Session
    session_model = SessionModel(id=s.id, data=s.data)
    save(session_model)
    return s
end
```

## Real-World Patterns

### User Login Flow

```julia
# In your login handler
function handle_login()
    user = authenticate_user(username, password)
    
    if user !== nothing
        session = Genie.Router.params(:session)
        
        # Store user information
        GenieSession.set!(session, :user_id, user.id)
        GenieSession.set!(session, :username, user.username)
        GenieSession.set!(session, :is_authenticated, true)
        
        # Session is automatically persisted by Genie.Router
    else
        return error_response(401, "Invalid credentials")
    end
end

# In protected routes
function protected_route()
    session = Genie.Router.params(:session)
    
    if !GenieSession.isset(session, :is_authenticated)
        return redirect_to_login()
    end
    
    user_id = GenieSession.get(session, :user_id)
    # ... handle authenticated request
end
```

### Shopping Cart Management

```julia
# Add to cart
function add_to_cart(product_id, quantity)
    session = Genie.Router.params(:session)
    
    cart = GenieSession.get(session, :cart, [])
    
    # Check if product already in cart
    existing = findfirst(item -> item["product_id"] == product_id, cart)
    
    if existing !== nothing
        cart[existing]["quantity"] += quantity
    else
        push!(cart, Dict("product_id" => product_id, "quantity" => quantity))
    end
    
    GenieSession.set!(session, :cart, cart)
    json("Cart updated")
end

# Checkout
function checkout()
    session = Genie.Router.params(:session)
    cart = GenieSession.get(session, :cart, [])
    
    if isempty(cart)
        return error_response(400, "Cart is empty")
    end
    
    # Process order...
    
    # Clear cart
    GenieSession.unset!(session, :cart)
end
```

### User Preferences

```julia
function update_preferences()
    session = Genie.Router.params(:session)
    
    prefs = Dict(
        "theme" => "dark",
        "language" => "en",
        "notifications_enabled" => true,
        "items_per_page" => 20
    )
    
    GenieSession.set!(session, :preferences, prefs)
    json("Preferences saved")
end

function get_preferences()
    session = Genie.Router.params(:session)
    
    prefs = GenieSession.get(session, :preferences, Dict())
    json(prefs)
end
```

### Multi-Step Forms

```julia
function step1_form()
    session = Genie.Router.params(:session)
    
    # Store step 1 data
    form_data = GenieSession.get(session, :form_data, Dict())
    form_data["step1"] = @params
    
    GenieSession.set!(session, :form_data, form_data)
    
    redirect("/step2")
end

function step2_form()
    session = Genie.Router.params(:session)
    
    # Retrieve and display previous data
    form_data = GenieSession.get(session, :form_data, Dict())
    
    # Store step 2 data
    form_data["step2"] = @params
    GenieSession.set!(session, :form_data, form_data)
    
    redirect("/step3")
end

def submit_form()
    session = Genie.Router.params(:session)
    
    # Get complete form data
    form_data = GenieSession.get(session, :form_data)
    
    # Process submission...
    
    # Clear session data
    GenieSession.unset!(session, :form_data)
end
```

## Session Lifecycle

### Creation

A session is automatically created when first accessed:

```julia
# In any route handler
session = Genie.Router.params(:session)  # Created if doesn't exist

# A unique session ID is generated and encrypted cookie is set
```

### Usage Across Requests

```
Request 1: POST /login
  └─ Session created with user_id=42
  └─ Encrypted session ID sent as cookie

Request 2: GET /dashboard  
  └─ Browser sends encrypted session ID cookie
  └─ Genie decrypts and loads session
  └─ Access user_id from session
  └─ Session updated if modified
  
Request 3: GET /profile
  └─ Browser sends same encrypted session ID
  └─ Session persisted across requests
```

### Logout / Clearing Sessions

```julia
function logout()
    session = Genie.Router.params(:session)
    
    # Option 1: Clear specific data
    GenieSession.unset!(session, :user_id)
    GenieSession.unset!(session, :is_authenticated)
    
    # Option 2: Clear entire session (implementation-dependent)
    # This would be handled by your storage adapter
    
    redirect("/login")
end
```

## Router Integration & Hooks

Genie automatically manages session persistence through the Router hook mechanism. Here's what happens behind the scenes:

### Automatic Persistence

```julia
# When you modify a session:
GenieSession.set!(session, :data, value)

# Genie.Router automatically calls after each request:
GenieSession.persist(request, response, params)

# This delegates to your adapter's persist function
```

### Hook Signature

The Router calls persist with this exact signature:

```julia
function GenieSession.persist(
    req::HTTP.Request,
    res::HTTP.Response,
    params::Dict{Symbol,Any}
) :: Tuple{HTTP.Request, HTTP.Response, Dict{Symbol,Any}}
    
    # Extract session from params
    # Persist to storage
    # Return unchanged request, response, params
    
    return req, res, params
end
```

### How to Implement

When creating a custom adapter, implement both signatures:

```julia
# For direct programmatic use
function GenieSession.persist(s::GenieSession.Session) :: GenieSession.Session
    # Save session
    return s
end

# For Router hook use
function GenieSession.persist(
    req::HTTP.Request,
    res::HTTP.Response,
    params::Dict{Symbol,Any}
)
    if haskey(params, GenieSession.PARAMS_SESSION_KEY)
        GenieSession.persist(params[GenieSession.PARAMS_SESSION_KEY])
    end
    return req, res, params
end
```

## Best Practices

### 1. Security

```julia
# ✅ DO: Store sensitive identifiers
GenieSession.set!(session, :user_id, user.id)

# ❌ DON'T: Store sensitive data directly
# DON'T: GenieSession.set!(session, :password, user.password)
# DON'T: GenieSession.set!(session, :credit_card, "4111111111111111")

# ✅ DO: Validate session data on each request
function get_user_from_session()
    session = Genie.Router.params(:session)
    user_id = GenieSession.get(session, :user_id)
    
    # Verify user still exists and is valid
    user = User |> (u -> u.id == user_id) |> findone
    
    return user
end
```

### 2. Performance

```julia
# ✅ DO: Store only necessary data
# ✅ DO: Use IDs instead of full objects when possible
GenieSession.set!(session, :user_id, 42)  # Good

# ❌ DON'T: Store large objects
# User = load_full_user_with_all_relationships()
# GenieSession.set!(session, :user, user)  # Bad

# ✅ DO: Clean up old sessions
# Implement session garbage collection in your adapter
```

### 3. Data Organization

```julia
# ✅ DO: Organize related data together
user_context = Dict(
    "id" => user.id,
    "role" => user.role,
    "permissions" => user.permissions
)
GenieSession.set!(session, :user, user_context)

# ❌ DON'T: Scatter related data across session
GenieSession.set!(session, :user_id, user.id)
GenieSession.set!(session, :user_role, user.role)
GenieSession.set!(session, :user_permissions, user.permissions)
```

### 4. Expiration Strategy

```julia
# Track session creation/access time
GenieSession.set!(session, :created_at, now())
GenieSession.set!(session, :last_activity, now())

# Implement timeout in your adapter
function GenieSession.load(session_id::String)
    session = load_from_storage(session_id)
    
    if session !== nothing
        last_activity = GenieSession.get(session, :last_activity)
        
        # 30 minute timeout
        if now() - last_activity > Minute(30)
            delete_from_storage(session_id)
            return GenieSession.Session(session_id)
        end
    end
    
    return session
end
```

### 5. Testing Sessions

```julia
using Test
using GenieSession

@testset "Session Tests" begin
    # Create a session for testing
    session = GenieSession.Session("test_id")
    
    @testset "Setting and getting data" begin
        GenieSession.set!(session, :test_key, "test_value")
        @test GenieSession.get(session, :test_key) == "test_value"
    end
    
    @testset "Complex data structures" begin
        data = Dict("nested" => Dict("value" => 42))
        GenieSession.set!(session, :complex, data)
        @test GenieSession.get(session, :complex)["nested"]["value"] == 42
    end
    
    @testset "Default values" begin
        val = GenieSession.get(session, :nonexistent, "default")
        @test val == "default"
    end
end
```

## Troubleshooting

### Session Data Not Persisting

1. Check that your storage adapter's `persist()` function is implemented
2. Verify the storage location is writable (for file-based sessions)
3. Ensure the secret token is configured

```julia
# Debug session persistence
session = Genie.Router.params(:session)
GenieSession.set!(session, :debug, true)
println("Session ID: $(session.id)")
println("Session data: $(session.data)")
```

### Session ID Changes on Each Request

This usually means the session isn't being loaded correctly:

```julia
# Check your load() adapter implementation
# It should return the SAME session for the same ID

function GenieSession.load(session_id::String)
    # This must return a session with matching ID
    existing = get_from_storage(session_id)
    
    if existing !== nothing
        return existing  # Same session
    else
        return GenieSession.Session(session_id)  # New session
    end
end
```

### Sessions Lost After Restart

If using in-memory sessions (default in development), sessions are lost when the server restarts. For persistent storage, use `GenieSessionFileSession`:

```julia
using GenieSession
using GenieSessionFileSession
```

## Related Resources

- [GenieSession.jl GitHub](https://github.com/GenieFramework/GenieSession.jl)
- [Working with Cookies](Working_with_Cookies.md) - Learn about cookies and encryption
- [Router Documentation](../API/router.md) - Understanding Genie's Router
- [Genie Security](../API/encryption.md) - Security best practices

