# Working with Sessions

Sessions are crucial for maintaining user state across multiple HTTP requests (like keeping a user logged in or maintaining a shopping cart). Genie provides robust session management through the **GenieSession.jl** plugin, built on top of the secure `Genie.Cookies` infrastructure.

## What are Sessions?

A **session** stores user-specific data **on the server**. Unlike cookies, which store data in the client's browser, sessions keep the actual data secure on the backend and use an encrypted cookie (`__geniesid`) only as a transport key.

### Sessions vs. Cookies

| Aspect | Cookies | Sessions |
|---|---|---|
| **Storage** | Client Browser | Server (Memory/File/DB) |
| **Security** | Medium (can be stolen/read if not careful) | High (data never leaves the server) |
| **Size Limit** | ~4KB | Unlimited (depends on server storage) |
| **Data Type** | Strings only | Any Julia object (Dicts, Structs, Arrays) |
| **Best For** | UI preferences, opaque IDs | User Authentication, sensitive data |

---

## Configuration & Installation

### 1. Installation

GenieSession is usually included in standard Genie app templates. If you need to add it manually:

```julia
using Pkg
Pkg.add("GenieSession")
# For persistent file storage (Recommended for Production)
Pkg.add("GenieSessionFileSession") 
```

### 2. Global Security Configuration

Thanks to the integration with Genie's Cookie system, you **do not** need to configure low-level cookie options (like `HttpOnly` or `Secure`) inside the session code. The session automatically inherits the global defaults defined in your `config/env/*.jl`.

**Recommended Setup (`config/env/prod.jl`):**

```julia
using Genie

# Session cookies will obey these rules automatically:
Genie.config.cookie_defaults = Dict(
  "httponly" => true,      # Essential: JS cannot read the session ID
  "secure"   => true,      # Force HTTPS
  "samesite" => "strict",  # Maximum CSRF protection
  "maxage"   => 2592000    # Session valid for 30 days
)

# Mandatory: Secret token to encrypt the session ID
Genie.Secrets.secret_token!("your-generated-secret-token-here")
```

> **Note:** If you are building an API for an SPA on a different domain (CORS), use `samesite => "none"` and `secure => true`.

### 3. Choosing a Storage Adapter

In your main app file (`src/App.jl` or `bootstrap.jl`):

**Option A: In-Memory (Development)**
Fast, but data is lost if the server restarts.
```julia
using GenieSession
```

**Option B: File System (Production)**
Persistent and robust.
```julia
using GenieSession
using GenieSessionFileSession

# Optional: Custom path
GenieSessionFileSession.sessions_path("storage/sessions")
```

---

## Basic Usage

### Accessing and Modifying Data

The `session` object is retrieved via request parameters. If it doesn't exist, Genie creates a new one automatically.

```julia
using Genie, GenieSession

route("/cart/add") do
  # Retrieve current session
  session = Genie.Router.params(:session)

  # Write data (key, value)
  GenieSession.set!(session, :product_id, 101)
  GenieSession.set!(session, :qty, 5)

  "Product added"
end

route("/cart/view") do
  session = Genie.Router.params(:session)

  # Read data (with default value if missing)
  qty = GenieSession.get(session, :qty, 0)
  
  "You have $qty items"
end
```

### Removing Data

```julia
# Remove a specific key
GenieSession.unset!(session, :product_id)

# Check if key exists
if GenieSession.isset(session, :product_id)
  # ...
end
```

---

## User Authentication

The most common use case for sessions is Authentication. The Genie community uses the **`GenieAuthentication.jl`** plugin, which abstracts the complexity of managing user IDs in the session.

### 1. Setup

```julia
using GenieAuthentication
# Adds methods like authenticate(), current_user(), logout(), etc.
```

### 2. The Login Flow (HTML vs. SPA)

The session logic is identical, but the response format differs depending on your frontend.

#### Scenario A: Genie HTML App (Traditional MVC)
Uses `redirect` and Flash Messages.

```julia
route("/login", method = POST) do
  user = findone(User, username = params(:username))
  
  if !isnothing(user) && verify_password(user.password, params(:password))
    # Securely stores User ID in session
    authenticate(user.id, GenieSession.session(params()))
    
    return redirect(:dashboard)
  end
  
  flash("Invalid username or password")
  redirect(:login_page)
end
```

#### Scenario B: SPA API (React / Vue / Quasar)
Uses JSON responses. The browser handles the cookie automatically.

```julia
route("/api/login", method = POST) do
  user = findone(User, username = params(:username))
  
  if !isnothing(user) && verify_password(user.password, params(:password))
    # 1. Authenticate in Session (Server-Side)
    authenticate(user.id, GenieSession.session(params()))
    
    # 2. Return JSON (The __geniesid cookie is in the Set-Cookie header)
    return json(Dict("status" => "success", "user" => user.name))
  end
  
  json(Dict("error" => "Invalid credentials"), status=401)
end
```

### 3. Logging Out

The `logout` function removes the user ID from the session and handles cookie invalidation.

```julia
route("/logout", method = POST) do
  # Removes user from current session
  logout(GenieSession.session(params()))
  
  json(Dict("status" => "logged_out"))
end
```

---

## Flash Messages

Flash messages are temporary messages stored in the session that persist only until the **next request** (perfect for "Login Successful" or "Save Failed").

```julia
using GenieSession.Flash

route("/process") do
  # Set the message
  flash("Operation completed successfully!")
  redirect("/")
end

route("/") do
  # Read the message (it is automatically cleared after reading)
  msg = flash() 
  
  "System Message: $msg"
end
```

**Note for SPAs:** Flash messages are rarely useful for SPAs (React/Vue), as the frontend usually displays notifications based on the immediate JSON response rather than reading from a redirected session state.

---

## Storing Complex Data

Because sessions live on the server, you can store complex Julia structures (Nested Dicts, Arrays, Custom Structs) without worrying about JSON serialization limits or cookie size constraints.

```julia
# Example: Multi-step Wizard
route("/step1", method=POST) do
  session = GenieSession.session(params())
  
  complex_data = Dict(
    "user" => Dict("name" => "Alice", "roles" => ["admin", "editor"]),
    "history" => [10, 20, 30],
    "timestamp" => now()
  )
  
  GenieSession.set!(session, :wizard_data, complex_data)
  json("Saved")
end
```

---

## Common Troubleshooting

### "Session is lost on every request"
1.  Check if the browser is accepting cookies.
2.  **Development Environment:** If accessing via IP (`192.168.x.x`) and your config has `secure => true`, the browser will block the cookie. Set `secure => false` in `config/env/dev.jl`.
3.  **Cross-Domain (CORS):** If your frontend is on `localhost:8080` and Genie on `localhost:8000`, you **must** configure:
    ```julia
    Genie.config.cookie_defaults = Dict(
      "samesite" => "none",
      "secure" => true
    )
    ```

### "Error: InvalidSessionIdException"
You forgot to configure the secret token. Add this to `config/secrets.jl`:
```julia
Genie.Secrets.secret_token!("your-secret-key-here")
```

---

## Next Steps

- [Cookie Configuration](Working_with_Cookies_Configuration.md) - Define global security policies.
- [Cookie Security](Working_with_Cookies_Security.md) - Learn about XSS/CSRF protection.
- [GenieAuthentication API](https://github.com/GenieFramework/GenieAuthentication.jl) - Official documentation for the auth plugin.