# Working with Cookies in Genie

Cookies are fundamental for maintaining state in web applications. The `Genie.Cookies` module provides a secure and flexible interface for handling them, including automatic encryption and protection against common attacks (XSS/CSRF).

## Table of Contents

- [Introduction](#introduction)
- [Basic Usage](#basic-usage)
  - [Setting Cookies](#setting-cookies)
  - [Reading Cookies](#reading-cookies)
  - [Removing Cookies](#removing-cookies)
- [Attributes and Security](#attributes-and-security)
- [SPA Integration (Quasar/Vue/React)](#spa-integration-quasarvuereact)
- [Note on Sessions](#note-on-sessions)

## Introduction

Genie encrypts cookie values by default using `Genie.Encryption`. This ensures that sensitive data is not exposed in plain text in the client's browser.

## Basic Usage

### Setting Cookies

The `set!` function modifies an `HTTP.Response` object. In practice, you usually create a content response (such as HTML or JSON) using Genie's renderers and attach the cookie to it before returning.

```julia
using Genie, Genie.Cookies, Genie.Renderer.Json, Genie.Renderer.Html

route("/login") do
  # 1. Create the response with the desired content
  res = html("<h1>Welcome to the System</h1>")

  # 2. Attach the cookie to the response (Encrypted by default)
  Genie.Cookies.set!(res, "user_id", "12345")
end

route("/preferences") do
  res = json(Dict("status" => "saved"))
  
  # Non-encrypted cookie (useful for reading via JavaScript on the frontend)
  Genie.Cookies.set!(res, "theme", "dark", encrypted=false)
end
```

### Reading Cookies

Use the `get` function to read cookies from the request object (`@request`). If the cookie was encrypted when set (default), it will be automatically decrypted upon reading.

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

# Reading with a default value if the cookie does not exist
route("/blog") do
  theme = Genie.Cookies.get(@request, "theme", "light", encrypted=false)
  "Current theme is: $theme"
end
```

### Removing Cookies

To remove a cookie, the HTTP standard requires you to set it again with an expiration date in the past (using a negative or zero `maxage`).

```julia
route("/logout") do
  res = redirect("/")
  
  # Overwrite the cookie with maxage=0 to force removal by the browser
  Genie.Cookies.set!(res, "user_id", "", Dict("maxage" => 0))
end
```

## Attributes and Security

You can pass a dictionary of attributes to control cookie behavior. This is crucial for application security.

### Key Attributes

| Attribute  | Description                                          | Recommendation                     |
|------------|------------------------------------------------------|-------------------------------------|
| `httponly` | Prevents JavaScript (client-side) from accessing the cookie. Protects against XSS. | `true` for tokens and sessions.     |
| `secure`   | Sends the cookie only if the connection is HTTPS.    | `true` in production.               |
| `samesite` | Controls sending in cross-site requests (CSRF). Modes: `lax`, `strict`, `none`. | `lax` (modern default) or `strict`. |
| `path`     | Restricts the cookie to a specific URL path.         | `/` (usually).                      |
| `maxage`   | Cookie lifetime in seconds.                          | Define as needed.                   |

### Secure Example (Recommended for Production)

```julia
route("/auth/token") do
  token = "abc-123-secret-token"
  
  res = json(Dict("auth" => true))
  
  attributes = Dict(
    "httponly" => true,    # Invisible to browser JS
    "secure"   => true,    # HTTPS only
    "samesite" => "strict",# Maximum CSRF protection
    "path"     => "/",
    "maxage"   => 3600     # Expires in 1 hour
  )

  Genie.Cookies.set!(res, "session_token", token, attributes)
end
```

## SPA Integration (Quasar/Vue/React)

If you are using Genie as an API for a frontend (Quasar, React, Vue), the recommended security pattern is to return JSON in the response body and set the authentication token in an `HttpOnly` cookie.

### Backend (Genie):

```julia
route("/api/login", method = POST) do
  # ... user validation logic ...
  
  # Return JSON so the frontend knows the operation succeeded
  res = json(Dict("user" => "Admin", "redirect" => "/dashboard"))
  
  # Set the token in a secure cookie that JS cannot read
  # The browser will automatically send this cookie in subsequent requests
  Genie.Cookies.set!(res, "auth_token", "secure_jwt_here", Dict(
    "httponly" => true,
    "samesite" => "lax",
    "path" => "/"
  ))
end
```

### Frontend (e.g., Quasar/Axios):

On the frontend, you do not need to read the cookie manually. Just ensure that the HTTP client (e.g., Axios) is configured to send credentials (cookies):

```javascript
// Axios configuration
axios.defaults.withCredentials = true;
```

## Note on Sessions

While it is technically possible to implement sessions manually using `Genie.Cookies`, it is **not recommended**.

Genie has a robust, dedicated module for this: `Genie.Sessions`. Use `Genie.Cookies` for:
- Simple data
- UI preferences (light/dark mode)
- Tracking
- Flags

Use `Genie.Sessions` for:
- User login
- Shopping carts
- Complex state data

`Genie.Sessions` uses `Genie.Cookies` internally to manage the session ID but abstracts away the complexity of storage and security.
