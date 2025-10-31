"""
Provides Genie with encryption and decryption capabilities.
"""
module Encryption

import Genie, Nettle

const ENCRYPTION_METHOD = "AES256"


"""
    encrypt{T}(s::T) :: String

Encrypts `s`.
"""
function encrypt(s::T)::String where T
  (key32, iv16) = encryption_sauce()
  encryptor = Nettle.Encryptor(ENCRYPTION_METHOD, key32)

  Nettle.encrypt(encryptor, :CBC, iv16, Nettle.add_padding_PKCS5(Vector{UInt8}(s), 16)) |> bytes2hex
end


"""
    decrypt(s::String) :: String

Decrypts `s` (a `string` previously encrypted by Genie).
"""
function decrypt(s::String) :: String
  (key32, iv16) = encryption_sauce()
  decryptor = Nettle.Decryptor(ENCRYPTION_METHOD, key32)
  deciphertext = Nettle.decrypt(decryptor, :CBC, iv16, s |> hex2bytes)

  try
    String(Nettle.trim_padding_PKCS5(deciphertext))
  catch ex
    if Genie.Configuration.isprod()
      @debug ex
      @debug "Could not decrypt data"
    end
    ""
  end
end


"""
    encryption_sauce() :: Tuple{Vector{UInt8},Vector{UInt8}}

Generates a pair of key32 and iv16 with salt for encryption/decryption
"""
function encryption_sauce() :: Tuple{Vector{UInt8},Vector{UInt8}}
  if length(Genie.Secrets.secret_token()) < 64
    if ! Genie.Configuration.isprod()
      Genie.Secrets.secret_token!()
    else
      error("Can't encrypt - make sure that Genie.Secrets.secret_token!(token) is called in config/secrets.jl")
    end
  end

  token = Genie.Secrets.secret_token()
  passwd = token[1:32]
  salt = hex2bytes(token[33:64])
  Nettle.gen_key32_iv16(Vector{UInt8}(passwd), salt)
end

"""
    has_encryption_format(s::String)

Determines whether `s` has the correct format to be an encrypted value.
"""
function has_encryption_format(s::String, blocklength::Int = 32)
  l = length(s)
  (l > 0 && l % blocklength == 0) || return false
  for c in s
      c in '0':'9' || c in 'a':'f' || c in 'A':'F' || return false
  end
  true
end

"""
    trydecrypt(s::String)

Tests whether `s` contains an encrypted value and returns it, otherwise returns `""`.
Values can be wrapped in `__`.
CAVEAT: if the encrypted string was `""` it cannot not be distinguished from a decryption failure.
"""
function trydecrypt(s::String)
    if has_encryption_format(s)
        decrypt(s)
    elseif startswith(s, "__") && endswith(s, "__") && has_encryption_format(String(s[3:end-2]))
      decrypt(String(s[3:end-2]))
    else
      ""
    end
end

"""
    isencrypted(s::String)

Determines whether `s` contains an encrypted value.
"""
function isencrypted(s::String)
    length(trydecrypt(s)) > 0
end


"""
    get_env_secret!(key::String, default::Union{String, Nothing} = nothing; delete::Bool = Genie.isprod())

A method to safely consume confidential information from environment variables.
It retrieves a value from environment variable and stores the encrypted value back, to allow for later consumption or alternatively deletes the value.
Parameters:
- `default`: if ENV has no key `key` and if `default` is a `String`, return this value and store the encrypted value in `ENV`
- `delete`: if `true`, don't store the encrypted value, but rather delete the entry from `ENV`

This method is intended to be used in Docker containers where confidential information is often stored in environment variables.
In order to remove the unecrypted value from the memory, we store the encrypted version instead.

### Example

```julia-repl
julia> ENV["Hello"] = "World!"
"World!"

julia> get_env_secret!("Hello")
"World!"

julia> ENV["Hello"]
"__4c41b6c3edb4ed1c17a076119d164498__"

julia> get_env_secret!("Hello", delete = true)
"World!"

julia> haskey(ENV, "Hello")
false
```

"""
function get_env_secret!(key::String, default::Union{String, Nothing} = nothing; delete::Bool = Genie.isprod())
    if ! haskey(ENV, key)
        default === nothing && return ""
        delete || (ENV[key] = "__$(encrypt(default))__")
        return default
    end
    
    val = ENV[key]
    delete && delete!(ENV, key)
    newval = startswith(val, "__") ? trydecrypt(val) : ""
    if length(newval) > 0
        # val was encrypted so we return the decrypted value
        newval
    else
        delete || (ENV[key] = "__$(encrypt(val))__")
        val
    end
end

end
