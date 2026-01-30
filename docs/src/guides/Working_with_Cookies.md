# Working with Cookies in Genie

Cookies are fundamental for maintaining state in web applications. The `Genie.Cookies` module provides a secure and flexible interface for handling them, including automatic encryption, configuration defaults, and protection against common attacks (XSS/CSRF).

## Table of Contents

- [Quick Start: Choose Your Path](#quick-start-choose-your-path)
- [Introduction](#introduction)
- [Basic Usage](#basic-usage)
  - [Setting Cookies](#setting-cookies)
  - [Reading Cookies](#reading-cookies)
  - [Removing Cookies (Logout)](#removing-cookies-logout)
- [Attributes and Security](#attributes-and-security)
- [SPA Integration (Quasar/Vue/React)](#spa-integration-quasarvuereact)
- [Note on Sessions](#note-on-sessions)

## Quick Start: Choose Your Path

**Not sure if you need this guide?** Use this table to find the right documentation for your app type:

| Your App Type | Primary Guide | When to Read This Guide |
|---------------|---------------|------------------------|
| **Traditional HTML** (Genie views, redirects, forms) | [Working with Sessions](Working_with_Sessions.md) *(in development)* | Only for simple preferences like `"theme=dark"` or `"language=en"` |
| **SPA Backend** (React/Vue/Quasar API on different domain) | **This Guide** + [Cookie Security](Working_with_Cookies_Security.md) | JWT tokens, CORS cookies, HttpOnly auth |
| **Hybrid** (Genie views + some JSON APIs) | [Sessions](Working_with_Sessions.md) *(in development)* first | When you need fine-grained cookie control for specific endpoints |

> **TL;DR:** Building a traditional Genie app with `@yield` and redirects? Use sessions (coming soon) — they use cookies internally and handle all the security for you. For now, this guide covers direct cookie control needed for API backends.

---

## Introduction

Genie's cookie system is designed to be **secure by default**:
1.  **Encryption:** Values are encrypted using `Genie.Encryption` unless specified otherwise.
2.  **Defaults:** Global attributes (like `HttpOnly`) can be configured once and applied everywhere.
3.  **Auto-Correction:** The system automatically fixes insecure configurations (like `SameSite=None` without `Secure`).

## Basic Usage

### Setting Cookies

The `set!` function modifies an `HTTP.Response` object. In practice, you usually create a content response (such as HTML or JSON) and attach the cookie to it.

**Clean Style (Relying on Config Defaults):**
If you have configured your defaults in `config/env/*.jl`, your code stays clean:

```julia
using Genie, Genie.Cookies, Genie.Renderer.Json

route("/login") do
  # 1. Create response
  res = json(Dict("status" => "logged_in"))

  # 2. Set cookie (inherits HttpOnly, Path, SameSite from config)
  Genie.Cookies.set!(res, "auth_token", "secret_jwt_123")
end
```

**Manual Style (Overriding Defaults):**
You can also pass specific attributes for one-off cases:

```julia
route("/preferences") do
  res = json(Dict("status" => "saved"))
  
  # Non-encrypted, accessible by JS (HttpOnly=false)
  Genie.Cookies.set!(res, "theme", "dark", Dict("httponly" => false), encrypted=false)
end
```

### Reading Cookies

Use the `get` function to read cookies from the request object (`@request` or passed explicitly). If the cookie was encrypted when set (default), it is automatically decrypted.

```julia
route("/dashboard") do
  # Attempt to read the 'user_id' cookie
  user_id = Genie.Cookies.get(@request, "user_id")

  if user_id !== nothing
    "Hello, user $user_id"
  else
    "Please log in."
  end
end

# Reading with a default value and specific type
route("/counter") do
  # Returns Int(0) if cookie missing or invalid
  count = Genie.Cookies.get(@request, "count", 0) 
  "Visits: $count"
end
```

### Removing Cookies (Logout)

To remove a cookie, you must tell the browser to expire it. Genie makes this robust: simply set `maxage` to `0`.

Genie internally converts `maxage => 0` into `Expires: Thu, 01 Jan 1970...`, ensuring the browser deletes the cookie immediately.

```julia
route("/logout") do
  res = json(Dict("status" => "logged_out"))
  
  # Effectively deletes the cookie
  Genie.Cookies.set!(res, "auth_token", "", Dict("maxage" => 0))
end
```

## Attributes and Security

While you can set attributes manually, we recommend defining them in [Cookie Configuration](Working_with_Cookies_Configuration.md) to keep your app DRY.

### Key Attributes

| Attribute  | Description                                          | Recommendation                     |
|------------|------------------------------------------------------|-------------------------------------|
| `httponly` | Prevents JavaScript from accessing the cookie.       | `true` for tokens/sessions.         |
| `secure`   | Sends the cookie only over HTTPS.                    | `true` in production.               |
| `samesite` | Controls cross-site request behavior (CSRF).         | `lax` or `strict`.                  |
| `path`     | Restricts cookie to a URL path.                      | `/` (default).                      |
| `maxage`   | Lifetime in seconds. (0 = Delete).                   | Set global default in config.       |



> **Auto-Secure Feature:** If you set `samesite` to `"none"` (common for SPAs) but forget `secure`, Genie automatically enables `secure` to prevent browser errors.

## SPA Integration (Quasar/Vue/React)

If you use Genie as an API for a frontend, the recommended security pattern is: **Return JSON, Set HttpOnly Cookie.**

### Backend (Genie):

```julia
route("/api/login", method = POST) do
  # ... user validation ...
  
  res = json(Dict("user" => "Admin"))
  
  # Token stored in cookie (HttpOnly), not in JSON body
  # Attributes like SameSite/Path come from your config/env/prod.jl
  Genie.Cookies.set!(res, "auth_token", "secure_jwt")
end
```

### Frontend (e.g., Axios):

You do not need to read the cookie manually. Just configure the client to send credentials:

```javascript
axios.defaults.withCredentials = true;
```

## Note on Sessions

While you *can* build sessions manually with `Genie.Cookies`, it is **not recommended**.

Use the dedicated **`Genie.Sessions`** module for:
- User login state
- Shopping carts
- Complex data storage

`Genie.Sessions` uses `Genie.Cookies` internally to manage the session ID securely, abstracting away the storage details. Use `Genie.Cookies` directly only for simple flags (e.g., "cookie_consent=true") or lightweight preferences.

## HTML vs SPA Comparison

| Feature | Genie HTML Apps | SPA (Quasar/React) | Notes |
| --- | --- | --- | --- |
| Cookie Config | ✅ Useful | ✅ Useful | `SameSite="Lax"` is fine for HTML apps; SPAs on different domains may need `SameSite="None"`. |
| Auto-Secure (SameSite=None) | ✅ Useful | ✅ Useful | Genie automatically enables `Secure=true` when `SameSite=None`, preventing Chrome/Edge from rejecting cookies. |
| HttpOnly | ✅ Essential | ✅ Essential | Blocks JavaScript access, protecting both HTML and SPA clients from XSS attacks. |
| Logout Fix (max_age=0) | ✅ Useful | ✅ Useful | Works consistently everywhere because Genie sets `Expires=1970`. |
| Flash Messages | ✅ Useful | ❌ Not used | SPAs usually show flash messages from JSON responses instead of cookies. |
| Redirects | ✅ Native | ❌ Avoid | Classic apps can redirect; SPAs expect JSON and misbehave when axios/fetch receive redirects. |

---

**Next Steps:**
- Configure your app defaults in [Cookie Configuration](Working_with_Cookies_Configuration.md).
- Learn about security patterns in [Cookie Security](Working_with_Cookies_Security.md).