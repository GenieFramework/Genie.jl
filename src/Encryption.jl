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

Tests whether `s` contains an encrypted value and returns it, otherwise returns nothing.
"""
function trydecrypt(s::String)
    if has_encryption_format(s)
      x = decrypt(s)
      if length(x) > 0
        x
      else
        # if decryption returns "" check whether it was a decryption error or the value was really an empty string
        encrypt("") == s ? "" : nothing
      end
    else
      nothing
    end
end

"""
    isencrypted(s::String)

Determines whether `s` contains an encrypted value.
"""
function isencrypted(s::String)
    trydecrypt(s) !== nothing
end


"""
    get_env_secret!(key::String, default::Union{String, Nothing} = nothing; delete::Bool = false, encrypted::Bool = false)

A method to consume confidential information from environment variables. It reads `ENV[key]`, decrypts if the value is an encrypted marker, and then either deletes the entry or replaces it with an encrypted marker to reduce accidental exposure.

Parameters:
- key::String
- default::Union{String, Nothing} = nothing  
  - If `ENV[key]` is absent and `default` is a `String`, returns `default` and writes an encrypted marker to `ENV`.  
  - If `ENV[key]` is absent and `default` is `nothing`, returns `nothing`.
- delete::Bool = false  
  - If `true`, deletes `ENV[key]`; otherwise writes an encrypted marker to `ENV`.
- encrypted::Bool = false  
  - If `true`, returns the encrypted value; otherwise returns plaintext.

Behavior:
- Retrieves values from `ENV[key]`.
- Detects previously stored encrypted markers of the form `"__<ciphertext>__"` and returns
  the plaintext.
- If not deleting, sets `ENV[key]` to `"__\$(encrypt(plaintext))__"`; if deleting, removes `ENV[key]`.
- Mutates `ENV`.

Returns:
- By default, the plaintext value.
- If `encrypted = true`, the ciphertext.
- `nothing` if the key is missing and `default` was not provided.

Examples:
```julia-repl
julia> ENV["HELLO"] = "World!"
"World!"

julia> get_env_secret!("HELLO")
"World!"

julia> ENV["HELLO"]
"__<ciphertext>__"

julia> get_env_secret!("HELLO", delete = true)
"World!"

julia> haskey(ENV, "HELLO")
false

# Missing key with no default
julia> get_env_secret!("MISSING")

# nothing

# Return encrypted marker instead of plaintext
julia> ENV["TOKEN"] = "s3cr3t"
"s3cr3t"

julia> get_env_secret!("TOKEN", encrypted = true)
"__<ciphertext>__"
```
"""
function get_env_secret!(key::String, default::Union{String, Nothing} = nothing; delete::Bool = false, encrypted::Bool = false)
    local val::String, val_encrypted::String
    
    value_exists = haskey(ENV, key)
    ! value_exists && default === nothing && return nothing
    val = value_exists ? ENV[key] : default::String
    # check whether the value was previously encrypted and stored
    newval = value_exists && length(val) > 5 && startswith(val, "__") && endswith(val, "__") ? trydecrypt(String(val[3:end-2])) : nothing
    if newval !== nothing
      # decryption was successful
      val_encrypted = val
      val = newval::String
    else
      # only encrypt if needed, i.e. not to be deleted or output encrypted
      val_encrypted = ! delete || encrypted ? "__$(encrypt(val))__" : ""
    end
    if delete
      delete!(ENV, key)
    else
      ENV[key] = val_encrypted
    end
    
    encrypted ? val_encrypted : val
end

end
