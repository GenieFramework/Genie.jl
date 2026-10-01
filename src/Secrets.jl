"""
    module Secrets

Manage the application’s secret token: generation, storage, loading,
and file‐path utilities.

A secret token is used for all cryptographic operations in Genie (cookie signing,
encryption, HMAC).  By default, a temporary token is generated in development
if none is present.  In production, you should generate and commit a stable
`config/secrets.jl` file by calling `Genie.Secrets.secret_token!()` once.
"""
module Secrets

import Dates
import SHA
import Logging
import Revise
import Genie
import Random: rand!, RandomDevice

const SECRET_TOKEN = Ref{String}("") # global state
const SECRETS_FILE_NAME = "secrets.jl"

"""
    secret_token(generate_if_missing=true) :: String

Return the secret token used in the app for encryption and salting.

Usually, this token is defined through `Genie.Secrets.secret_token!` in the `config/secrets.jl` file.
Here, a temporary one is generated for the current session if no other token is defined and
`generate_if_missing` is true.

See [`Genie.Secrets.secret_token!`](@ref) and [`Genie.Secrets.load`](@ref).
"""
function secret_token(generate_if_missing::Bool = true; context::Union{Module,Nothing} = nothing)
  if isempty(SECRET_TOKEN[])
    isfile(joinpath(Genie.config.path_config, SECRETS_FILE_NAME)) &&
      Revise.includet(Genie.Loader.default_context(context), joinpath(Genie.config.path_config, SECRETS_FILE_NAME))

    if isempty(SECRET_TOKEN[]) && generate_if_missing && Genie.Configuration.isprod()
      @warn "
            No secret token is defined through `Genie.Secrets.secret_token!(\"token\")`. Such a token
            is needed to hash and to encrypt/decrypt sensitive data in Genie, including cookie
            and session data.

            If your app relies on cookies or sessions make sure you generate a valid token,
            otherwise the encrypted data will become unreadable between app restarts.

            You can resolve this issue by generating a valid `config/secrets.jl` file with a
            random token, calling `Genie.Generator.write_secrets_file()`.
            "
      secret_token!()
    end
  end

  SECRET_TOKEN[]
end


"""
    secret_token!(value = secret())

Define the secret token used in the app for encryption and salting.
"""
function secret_token!(value::AbstractString = secret())
  SECRET_TOKEN[] = value

  value
end


"""
    load(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing

Load (include) the framework's secrets.jl file into the app's module `context`.
The files are set up with `Revise` to be automatically reloaded.
"""
function load(root_dir::String = Genie.config.path_config; context::Union{Module,Nothing} = nothing) :: Nothing
  secrets_path = secret_file_path(root_dir)
  isfile(secrets_path) && Revise.includet(Genie.Loader.default_context(context), secrets_path)

  # check that the secrets_path has called Genie.secret_token!
  if isempty(secret_token(false)) # do not generate a temporary token in this check
    secret_token() # emits a warning and re-generates the token if secrets_path is not valid
  end

  nothing
end


"""
    secret()::String

Generate a new cryptographically secure random token (32 raw bytes → 64 hex chars)
using the system RNG.

# Examples
```jldoctest
julia> using Genie.Secrets
julia> length(Secrets.secret())
64
```

See also [`Genie.Secrets.secret_token!`](@ref).
"""
function secret() :: String
  buf = Vector{UInt8}(undef, 32)
  rand!(RandomDevice(), buf)
  bytes2hex(buf)
end

"""
    secret_file_exists(root_dir = Genie.config.path_config)::Bool

Check whether `secrets.jl` exists in `root_dir`.

See also [`Genie.Secrets.secret_file_path`](@ref).
"""
function secret_file_exists(root_dir::String = Genie.config.path_config) :: Bool
  secret_file_path(root_dir) |> isfile
end

"""
    secret_file_path(root_dir = Genie.config.path_config)::String

Return the full filesystem path to `secrets.jl` under `root_dir`.
See also [`Genie.Secrets.secret_file_exists`](@ref).
"""
function secret_file_path(root_dir::String = Genie.config.path_config) :: String
  joinpath(root_dir, SECRETS_FILE_NAME)
end

"""
read_secret(name::String)::Union{String,Nothing}
Look first in Docker’s `/run/secrets/NAME`, then in ENV["NAME"].
Returns `nothing` if neither is set or is empty.
"""
function read_secret(name::String)::Union{String,Nothing}
  # docker-secrets always lowercase
  docker_file=joinpath("/run/secrets", lowercase(name))
  if isfile(docker_file)
    tok=strip(read(docker_file, String))
    isempty(tok) ? nothing : tok
  elseif haskey(ENV,name) && !isempty(ENV[name])
    ENV[name]
  else
    nothing
  end
end

end
