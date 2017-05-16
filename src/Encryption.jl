"""
Provides Genie with encryption and decryption capabilities.
"""
module Encryption

using Genie, App, Nettle

const ENCRYPTION_METHOD = "AES256"


"""
    encrypt{T}(s::T) :: String

Encrypts `s`.
"""
function encrypt{T}(s::T) :: String
  (key32, iv16) = encryption_sauce()
  encryptor = Encryptor(ENCRYPTION_METHOD, key32)

  Nettle.encrypt(encryptor, :CBC, iv16, add_padding_PKCS5(s.data, 16)) |> bytes2hex
end


"""
    decrypt(s::String) :: String

Decrypts `s` (a `string` previously encrypted by Genie).
"""
function decrypt(s::String) :: String
  (key32, iv16) = encryption_sauce()
  decryptor = Decryptor(ENCRYPTION_METHOD, key32)
  deciphertext = Nettle.decrypt(decryptor, :CBC, iv16, s |> hex2bytes)

  String(trim_padding_PKCS5(deciphertext))
end

function encryption_sauce()
  passwd = App.secret_token()[1:32]
  salt = hex2bytes(App.secret_token()[33:64])

  gen_key32_iv16(passwd.data, salt)
end

end
