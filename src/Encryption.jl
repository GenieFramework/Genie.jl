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

  String(Nettle.trim_padding_PKCS5(deciphertext))
end


"""
    encryption_sauce() :: Tuple{Vector{UInt8},Vector{UInt8}}

Generates a pair of key32 and iv16 with salt for encryption/decryption
"""
function encryption_sauce() :: Tuple{Vector{UInt8},Vector{UInt8}}
  if length(Genie.Secrets.secret_token()) < 64
    if !Genie.Configuration.isprod()
      @error "Invalid Genie.Secrets.secret_token() with less than 64 characters; using a temporary token"
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

end
