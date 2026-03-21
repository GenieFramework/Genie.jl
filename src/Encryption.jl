"""
Encryption
High-level symmetric encryption for Genie apps.
Under the hood it uses XChaCha20-Poly1305 authenticated encryption,
wrapping everything in two simple functions:

- `encrypt`](@ref): Return a hex string containing nonce ∥ ciphertext ∥ tag.
- `decrypt`](@ref): verify the tag, decrypts, and return
  the original plaintext (or an empty string on any error).

All keys are derived from your 64-hex-char secret token.
See also `encrypt`](@ref) and `decrypt`](@ref).
"""
module Encryption
using Sodium
import Sodium.LibSodium
import Genie.Secrets: secret_token

const KEYBYTES=LibSodium.crypto_aead_xchacha20poly1305_ietf_KEYBYTES
const NONCEBYTES=LibSodium.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES
const TAGBYTES=LibSodium.crypto_aead_xchacha20poly1305_ietf_ABYTES

"""
_derive_key()::Vector{UInt8}

Derive a 32-byte encryption key from the Genie secret token.
Secret token must be exactly 64 hex characters.

# Example

```jldoctest
julia> using Genie
julia> Genie.Secrets.secret_token!(
       "f00df00df00df00df00df00df00df00df00df00df00df00df00df00df00df00d");
julia> key = Genie.Encryption._derive_key()
32-element Vector{UInt8}: [...]
```
"""
function _derive_key()
  tok=secret_token(false)
  isempty(tok) && error("No Genie secret_token found; call `Genie.Secrets.secret_token!()` first")
  length(tok)!=64 && error("Secret token must be exactly 64 hex chars")
  hex2bytes(tok)
end

"""
encrypt(plain::AbstractString)::String

Encrypt `plain` using XChaCha20-Poly1305 authenticated encryption.
Returns `hex(nonce ∥ ciphertext ∥ tag)`.

The nonce is randomly generated for each encryption, and the key is
derived from your secret token. No associated data is used.

# Examples

```jldoctest
julia> using Genie; using Genie.Secrets
julia> Genie.Secrets.secret_token!(
       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
julia> token = Genie.Encryption.encrypt("hello");
julia> typeof(token)
String
```
"""
function encrypt(plain::AbstractString)::String
  key=_derive_key()
  nonce=rand(UInt8,NONCEBYTES)
  msg=collect(codeunits(plain))
  outlen=UInt64(length(msg)+TAGBYTES)
  c=Vector{UInt8}(undef,Int(outlen))
  clen=Ref{UInt64}()

  res=LibSodium.crypto_aead_xchacha20poly1305_ietf_encrypt(
    c,clen,
    msg,UInt64(length(msg)),
    C_NULL,UInt64(0),
    C_NULL,
    nonce,
    key,
  )
  res!=0 && error("AEAD‐encrypt failed (code=$res)")

  bytes2hex(vcat(nonce,c[1:Int(clen[])]))
end

"""
decrypt(token::String)::String

Reverse of `encrypt`: hex→(nonce ∥ ciphertext ∥ tag), verify authentication,
and decrypt using XChaCha20-Poly1305.

# Examples

```jldoctest
julia> using Genie,Genie.Secrets
julia> Genie.Secrets.secret_token!(
       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
julia> t = Genie.Encryption.encrypt("world");
julia> Genie.Encryption.decrypt(t)
"world"
julia> Genie.Encryption.decrypt("badhex")
""
```
"""
function decrypt(token::String)::String
  raw=try
    hex2bytes(token)
  catch
    return ""
  end

  length(raw)<=NONCEBYTES+TAGBYTES && return ""

  key=_derive_key()
  nonce=raw[1:NONCEBYTES]
  body=raw[NONCEBYTES+1:end]
  mlen=Ref{UInt64}()
  m=Vector{UInt8}(undef,length(body))

  res=LibSodium.crypto_aead_xchacha20poly1305_ietf_decrypt(
    m,mlen,
    C_NULL,
    body,UInt64(length(body)),
    C_NULL,UInt64(0),
    nonce,
    key,
  )
  res!=0 && return ""

  String(m[1:Int(mlen[])])
end

end
