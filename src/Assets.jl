"""
Helper functions for working with frontend assets (including JS, CSS, etc files).
"""
module Assets

import Genie, Genie.Configuration, Genie.Router, Genie.WebChannels
import Genie.Renderer.Json

export include_asset, css_asset, js_asset, js_settings, css, js
export embedded, channels_script, channels_support
export favicon_support


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
const css = css_asset


"""
    js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a js asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicating if a fingerprint (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:js, file_name, fingerprinted = fingerprinted)
end
const js = js_asset


"""
    js_settings() :: string

Sets up a `window.Genie.Settings` JavaScript object which exposes relevant Genie app settings from `Genie.config`
"""
function js_settings(channel::String = Genie.config.webchannels_default_route) :: String
  settings = Json.JSONParser.json(Dict(
    :server_host                      => Genie.config.server_host,
    :server_port                      => Genie.config.server_port,
    :websockets_port                  => Genie.config.websockets_port,
    :webchannels_default_route        => channel,
    :webchannels_subscribe_channel    => Genie.config.webchannels_subscribe_channel,
    :webchannels_unsubscribe_channel  => Genie.config.webchannels_unsubscribe_channel,
    :webchannels_autosubscribe        => Genie.config.webchannels_autosubscribe,
  ))

  """
  window.Genie = {};
  Genie.Settings = $settings
  """
end


"""
    embeded(path::String) :: String

Reads and outputs the file at `path` within Genie's root package dir
"""
function embedded(path::String) :: String
  read(joinpath(@__DIR__, "..", path) |> normpath, String)
end


"""
    embeded_path(path::String) :: String

Returns the path relative to Genie's root package dir
"""
function embedded_path(path::String) :: String
  joinpath(@__DIR__, "..", path) |> normpath
end


"""
    channels() :: String

Outputs the channels.js file included with the Genie package
"""
function channels(channel::String = Genie.config.webchannels_default_route) :: String
  string(js_settings(channel), embedded(joinpath("files", "embedded", "channels.js")))
end


"""
    channels_script() :: String

Outputs the channels JavaScript content within `<script>...</script>` tags, for embedding into the page.
"""
function channels_script(channel::String = Genie.config.webchannels_default_route) :: String
"""
<script>
$(channels(channel))
</script>
"""
end


function channels_subscribe(channel::String = Genie.config.webchannels_default_route) :: Nothing
  Router.channel("/$(channel)/$(Genie.config.webchannels_subscribe_channel)") do
    WebChannels.subscribe(Genie.Requests.wsclient(), channel)

    "Subscription: OK"
  end

  Router.channel("/$(channel)/$(Genie.config.webchannels_unsubscribe_channel)") do
    WebChannels.unsubscribe(Genie.Requests.wsclient(), channel)
    WebChannels.unsubscribe_disconnected_clients()

    "Unsubscription: OK"
  end

  nothing
end


"""
    channels_support(channel = Genie.config.webchannels_default_route) :: String

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function channels_support(channel::String = Genie.config.webchannels_default_route) :: String
  Router.route("/js/$(Genie.config.webchannels_js_file)") do
    Genie.Renderer.Js.js(channels(channel))
  end

  channels_subscribe(channel)

  "<script src=\"/js/$(Genie.config.webchannels_js_file)?v=$(Genie.Configuration.GENIE_VERSION)\"></script>"
end


"""
    favicon_support() :: String

Outputs the `<link>` tag for referencing the favicon file embedded with Genie.
"""
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
