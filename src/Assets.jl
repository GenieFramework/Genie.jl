"""
Helper functions for working with frontend assets (including JS, CSS, etc files).
"""
module Assets
using DocStringExtensionsMock

import Genie, Genie.Configuration, Genie.Router, Genie.WebChannels, Genie.WebThreads
import Genie.Renderer.Json

export include_asset, css_asset, js_asset, js_settings, css, js
export embedded, channels_script, channels_support, webthreads_script, webthreads_support
export favicon_support


### PUBLIC ###


"""
$TYPEDSIGNATURES

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. The `file_name` should not include the extension.
"""
function include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol}) :: String
  "$(Genie.config.base_path)$(string(asset_type))/$(string(file_name))$(".$asset_type")"
end


"""
$TYPEDSIGNATURES

Path to a css asset. The `file_name` should not include the extension.
"""
function css_asset(file_name::String) :: String
  include_asset(:css, file_name)
end
const css = css_asset


"""
$TYPEDSIGNATURES

Path to a js asset. `file_name` should not include the extension.
"""
function js_asset(file_name::String) :: String
  include_asset(:js, file_name)
end
const js = js_asset


"""
$TYPEDSIGNATURES

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
    :webchannels_eval_command         => Genie.config.webchannels_eval_command,
    :webchannels_timeout              => Genie.config.webchannels_timeout,

    :webthreads_default_route         => Genie.config.webthreads_default_route,
    :webthreads_js_file               => Genie.config.webthreads_js_file,
    :webthreads_pull_route            => Genie.config.webthreads_pull_route,
    :webthreads_push_route            => Genie.config.webthreads_push_route,

    :base_path                        => Genie.config.base_path,
  ))

  """
  window.Genie = {};
  Genie.Settings = $settings
  """
end


"""
$TYPEDSIGNATURES

Reads and outputs the file at `path` within Genie's root package dir
"""
function embedded(path::String) :: String
  read(joinpath(@__DIR__, "..", path) |> normpath, String)
end


"""
$TYPEDSIGNATURES

Returns the path relative to Genie's root package dir
"""
function embedded_path(path::String) :: String
  joinpath(@__DIR__, "..", path) |> normpath
end


"""
$TYPEDSIGNATURES

Outputs the channels.js file included with the Genie package
"""
function channels(channel::String = Genie.config.webchannels_default_route) :: String
  string(js_settings(channel), embedded(joinpath("files", "embedded", "channels.js")))
end


"""
$TYPEDSIGNATURES

Outputs the channels JavaScript content within `<script>...</script>` tags, for embedding into the page.
"""
function channels_script(channel::String = Genie.config.webchannels_default_route) :: String
"""
<script>
$(channels(channel))
</script>
"""
end


"""
$TYPEDSIGNATURES
"""
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
$TYPEDSIGNATURES

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function channels_support(channel::String = Genie.config.webchannels_default_route) :: String
  endpoint = (channel == Genie.config.webchannels_default_route) ?
              "/js/$(Genie.config.webchannels_js_file)" :
              "/js/$(channel)/$(Genie.config.webchannels_js_file)"
  Router.route(endpoint) do
    Genie.Renderer.Js.js(channels(channel))
  end

  channels_subscribe(channel)

  "<script src=\"$(Genie.config.base_path)$(endpoint[2:end])\"></script>"
end


########


"""
$TYPEDSIGNATURES

Outputs the webthreads.js file included with the Genie package
"""
function webthreads(channel::String = Genie.config.webthreads_default_route) :: String
  string(js_settings(channel),
          embedded(joinpath("files", "embedded", "pollymer.min.js")),
          embedded(joinpath("files", "embedded", "webthreads.js")))
end


"""
$TYPEDSIGNATURES

Outputs the channels JavaScript content within `<script>...</script>` tags, for embedding into the page.
"""
function webthreads_script(channel::String = Genie.config.webthreads_default_route) :: String
"""
<script>
$(webthreads(channel))
</script>
"""
end


"""
$TYPEDSIGNATURES
"""
function webthreads_subscribe(channel::String = Genie.config.webthreads_default_route) :: Nothing
  Router.route("/$(channel)/$(Genie.config.webchannels_subscribe_channel)", method = Router.GET) do
    WebThreads.subscribe(Genie.Requests.wtclient(), channel)

    Dict("Subscription" => "OK") |> Genie.Renderer.Json.json
  end

  Router.route("/$(channel)/$(Genie.config.webchannels_unsubscribe_channel)", method = Router.GET) do
    WebThreads.unsubscribe(Genie.Requests.wtclient(), channel)
    WebThreads.unsubscribe_disconnected_clients()

    Dict("Unubscription" => "OK") |> Genie.Renderer.Json.json
  end

  nothing
end


"""
$TYPEDSIGNATURES
"""
function webthreads_push_pull(channel::String = Genie.config.webthreads_default_route) :: Nothing
  Router.route("/$(channel)/$(Genie.config.webthreads_pull_route)", method = Router.POST) do
    WebThreads.pull(Genie.Requests.wtclient(), channel)
  end

  Router.route("/$(channel)/$(Genie.config.webthreads_push_route)", method = Router.POST) do
    WebThreads.push(Genie.Requests.wtclient(), channel, Router.params(Genie.PARAMS_RAW_PAYLOAD))
  end

  nothing
end


"""
$TYPEDSIGNATURES

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function webthreads_support(channel::String = Genie.config.webthreads_default_route) :: String
  endpoint = (channel == Genie.config.webthreads_default_route) ?
              "/js/$(Genie.config.webthreads_js_file)" :
              "/js/$(channel)/$(Genie.config.webthreads_js_file)"

  Router.route(endpoint) do
    Genie.Renderer.Js.js(webthreads(channel))
  end

  webthreads_subscribe(channel)
  webthreads_push_pull(channel)

  "<script src=\"$(Genie.config.base_path)$(endpoint[2:end])\"></script>"
end


#######


"""
$TYPEDSIGNATURES

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

  "<link rel=\"icon\" type=\"image/x-icon\" href=\"$(Genie.config.base_path)favicon.ico\" />"
end

end
