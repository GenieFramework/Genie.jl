# Configuring Cookies in Genie

Genie provides a powerful configuration system that allows you to define application-wide defaults for your cookies. This ensures your application is secure by default while allowing for flexibility when specific routes need different behavior.

This system is fully integrated with Genie's environment loading (`dev`, `test`, `prod`), making it easy to manage security policies across different deployment stages.

## Table of Contents

- [Global Configuration](#global-configuration)
- [Environment-Specific Configurations](#environment-specific-configurations)
- [Configuration Reference](#configuration-reference)
- [Runtime Overrides](#runtime-overrides)
- [Common Recipes](#common-recipes)

## Global Configuration

You can define baseline defaults that apply to **every** cookie set by your application. This is typically done in your app's configuration files.

### Basic Setup

In a standard Genie app structure, you can add this to `config/initializers/cookies.jl` (or `config/global.jl`):

```julia
# config/initializers/cookies.jl
using Genie

# Define defaults for ALL cookies
Genie.config.cookie_defaults = Dict(
  "httponly" => true,       # Prevent XSS (JavaScript access blocked)
  "path"     => "/",        # Available across the whole site
  "maxage"   => 604800,     # 7 days (in seconds)
  "samesite" => "lax"       # Modern browser default
)
```

Now, when you set a cookie in your controller or route, it inherits these settings automatically:

```julia
# routes.jl
route("/login", method = POST) do
  # ... auth logic ...
  
  # Automatically gets: HttpOnly, Path=/, Max-Age=7 days, SameSite=Lax
  Genie.Cookies.set!(res, "auth_token", token)
end
```

## Environment-Specific Configurations

The most common pattern in the Genie community is to change cookie security based on the environment (Development vs. Production).

### 1. Development (`config/env/dev.jl`)

In development, we often use `http://localhost`, which supports `Secure` cookies, but if testing on a local network IP (e.g., mobile testing), `Secure` might break things.

```julia
# config/env/dev.jl
using Genie

Genie.config.cookie_defaults = Dict(
  "httponly" => true,
  "secure"   => false,   # Allow HTTP connections
  "samesite" => "lax",   # Good balance for dev
  "path"     => "/"
)
```

### 2. Production (`config/env/prod.jl`)

In production, security is non-negotiable.

```julia
# config/env/prod.jl
using Genie

Genie.config.cookie_defaults = Dict(
  "httponly" => true,
  "secure"   => true,      # STRICTLY HTTPS only
  "samesite" => "strict",  # Maximum CSRF protection
  "path"     => "/",
  "maxage"   => 86400      # 1 day (shorter life for prod tokens)
)
```

## Configuration Reference

The `Genie.config.cookie_defaults` dictionary accepts the following keys (strings):

| Key | Type | Description |
|---|---|---|
| `"httponly"` | `Bool` | If `true`, hides cookie from JavaScript (prevents XSS). |
| `"secure"` | `Bool` | If `true`, cookie is only sent over HTTPS. |
| `"samesite"` | `String` | `"Lax"`, `"Strict"`, or `"None"`. Controls CSRF behavior. |
| `"path"` | `String` | URL path prefix where cookie is valid. Default: `"/"`. |
| `"maxage"` | `Int/String`| Lifetime in seconds. **Note:** Genie auto-converts `0` to a logout (Expires 1970). |
| `"domain"` | `String` | Domain scope (e.g., `".example.com"` for subdomains). |
| `"expires"` | `String` | Explicit expiration date (RFC 2822). Prefer `maxage` for simplicity. |

> **Note:** Configuration keys are case-insensitive (`"HttpOnly"` and `"httponly"` both work).

## Safety Limits (Max Size)

Cookies travel in HTTP headers, so oversized values can overflow proxy buffers or be rejected by the browser. Genie lets you enforce a safe maximum size for **incoming** cookies.

```julia
# config/global.jl
Genie.config.max_cookie_size = 2048  # Bytes
```

### How it works

1.  When you call `Genie.Cookies.get(req, "key")`, Genie measures the byte length of the cookie value.
2.  If `length(value) > max_cookie_size`, the cookie is silently ignored (the call returns `nothing`).
3.  A debug log warns: `Cookie value exceeds maximum size...`, so you can detect attackers who flood cookies.

**Recommendation:** Set this limit to `4096` (4 KB) to align with the standard browser header size and avoid DoS vectors that abuse large cookies.

## Runtime Overrides

Sometimes a specific cookie needs to break the rules. You can override defaults by passing a `Dict` to the `set!` function.

### Example: Public Preference Cookie
Even if your global config enforces `httponly => true`, you might want a UI theme cookie to be readable by JavaScript.

```julia
using Genie.Cookies

route("/api/theme", method = POST) do
  # ... logic ...
  
  # Override defaults specifically for this cookie
  Genie.Cookies.set!(res, "theme", "dark", Dict(
    "httponly" => false,   # Allow JS to read this
    "maxage"   => 31536000 # 1 year
  ), encrypted = false)    # No need to encrypt "dark"
end
```

## Common Recipes

### 1. The SPA / Mobile App Backend (CORS)

If your frontend runs on a different domain (e.g., Quasar/React on `localhost:8080` talking to Genie on `localhost:8000`), you need specific settings to allow the browser to send cookies.

**Recommended Config:**

```julia
# config/env/dev.jl or prod.jl
Genie.config.cookie_defaults = Dict(
  "samesite" => "none",  # Required for Cross-Origin requests
  "secure"   => true,    # Browser REQUIRES Secure if SameSite=None
  "httponly" => true
)
```

> **Genie Auto-Secure:** If you configure `"samesite" => "none"` but forget `"secure" => true`, Genie will automatically enable Secure mode to prevent your app from breaking in Chrome/Edge.

### 2. Subdomain Sharing

To share cookies between `app.mysite.com` and `api.mysite.com`:

```julia
# config/env/prod.jl
Genie.config.cookie_defaults = Dict(
  "domain"   => ".mysite.com", # Note the leading dot
  "httponly" => true,
  "secure"   => true
)
```

### 3. Short-Lived Flash Messages

For "flash" messages (one-time notifications), you don't need `Genie.config` defaults. Just set a short maxage inline:

```julia
Genie.Cookies.set!(res, "flash_msg", "Saved!", Dict("maxage" => 5), encrypted=false)
```