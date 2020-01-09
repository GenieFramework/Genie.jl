"""
Helper functions for working with frontend assets (including JS, CSS, etc files).
"""
module Assets

import Revise
import Genie, Genie.Configuration, Genie.Router, Genie.WebChannels

export include_asset, css_asset, js_asset


### PUBLIC ###


"""
    include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol};
                  fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. The `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicating if a fingerprint (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol};
                        fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  asset_type = string(asset_type)
  file_name = string(file_name)

  suffix = fingerprinted ? "-" * Genie.ASSET_FINGERPRINT * ".$asset_type" : ".$asset_type"
  "/$asset_type/$(file_name)$(suffix)"
end


"""
    css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a css asset. The `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicating if a fingerprint (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:css, file_name, fingerprinted = fingerprinted)
end


"""
    js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a js asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicating if a fingerprint (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:js, file_name, fingerprinted = fingerprinted)
end


"""
    embeded(path::String) :: String

Reads and outputs the file at `path` within Genie's root package dir
"""
function embedded(path::String) :: String
  read(joinpath(@__DIR__, "..", path) |> normpath, String)
end


"""
    channels() :: String

Outputs the channels.js file included with the Genie package
"""
function channels() :: String
  embedded(joinpath("files", "new_app", "public", "js", "app", "channels.js"))
end


function channels_script() :: String
"""
<script>
$(channels())
</script>
"""
end


function channels_support() :: String
  Router.route("/$(Genie.config.webchannels_default_route)/$(Genie.config.webchannels_js_file)") do
    Genie.Renderer.Js.js(channels())
  end

  Router.channel("/$(Genie.config.webchannels_default_route)/$(Genie.config.webchannels_subscribe_channel)") do
    WebChannels.subscribe(Genie.Requests.wsclient(), Genie.config.webchannels_default_route)
    "OK"
  end

  "<script src=\"/$(Genie.config.webchannels_default_route)/$(Genie.config.webchannels_js_file)\"></script>"
end


function favicon_support() :: String
  Router.route("/favicon.ico") do
    Genie.Renderer.respond(
      Genie.Renderer.WebRenderable(
        body = embedded(joinpath("files", "new_app", "public", "favicon.ico")),
        content_type = :favicon
      )
    )
  end

  "<link rel=\"icon\" type=\"image/x-icon\" href=\"/favicon.ico\" />"
end

end