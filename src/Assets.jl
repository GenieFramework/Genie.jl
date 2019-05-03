module Assets

using Genie, Genie.Loggers, Genie.Configuration

export include_asset, css_asset, js_asset

"""
    include_asset(asset_type::Symbol, file_name::String; fingerprinted = Genie.config.assets_fingerprinted) :: String

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol}; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  asset_type = string(asset_type)
  file_name = string(file_name)

  suffix = fingerprinted ? "-" * Genie.ASSET_FINGERPRINT * ".$asset_type" : ".$asset_type"
  "/$asset_type/$(file_name)$(suffix)"
end


"""
    css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a css asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:css, file_name, fingerprinted = fingerprinted)
end


"""
    js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a js asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:js, file_name, fingerprinted = fingerprinted)
end

end
