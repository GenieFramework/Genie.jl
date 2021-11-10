"""
Helper functions for working with frontend assets (including JS, CSS, etc files).
"""
module Assets

import Genie, Genie.Configuration, Genie.Router, Genie.WebChannels, Genie.WebThreads
import Genie.Renderer.Json

export include_asset, css_asset, js_asset, js_settings, css, js
export embedded, channels_script, channels_support, webthreads_script, webthreads_support
export favicon_support


### PUBLIC ###

"""
    mutable struct AssetsConfig

Manages the assets configuration for the current package. Define your own instance of AssetsConfig if you want to
add support for asset management for your package through Genie.Assets.
"""
Base.@kwdef mutable struct AssetsConfig
  host::String = Genie.config.base_path
  package::String = "Genie.jl"
  version::String = "master"
end

const assets_config = AssetsConfig()

"""
    assets_config!(packages::Vector{Module}; config...) :: Nothing

Utility function which allows bulk configuration of the assets.

### Example

```julia
Genie.Assets.assets_config!([Genie, Stipple, StippleUI], host = "https://cdn.statically.io/gh/GenieFramework")
```
"""
function assets_config!(packages::Vector{Module}; config...) :: Nothing
  for p in packages
    package_config = getfield(p, :assets_config)

    for (k,v) in config
      setfield!(package_config, k, v)
    end
  end

  nothing
end

"""
    external_assets(...) :: Bool

Returns true if the current package is using external assets.
"""
function external_assets(host::String) :: Bool
  startswith(host, "http")
end
function external_assets(ac::AssetsConfig) :: Bool
  external_assets(ac.host)
end
function external_assets() :: Bool
  external_assets(assets_config)
end

"""
    asset_path(...) :: String

Generates the path to an asset file.
"""
function asset_path(; file::String, host::String = Genie.config.base_path, package::String = "", version::String = "",
                      type::String = "$(split(file, '.')[end])", path::String = "", min::Bool = false,
                      ext::String = "$(endswith(file, type) ? "" : ".$type")", skip_ext::Bool = false) :: String
  (external_assets(host) ? "" : "/") *
    join(filter([host, package, version, "assets", type, path, file*(min ? ".min" : "")*(skip_ext ? "" : ext)]) do part
      ! isempty(part)
  end, '/') |> lowercase
end
function asset_path(ac::AssetsConfig, tp::Union{Symbol,String}; type::String = string(tp), path::String = "",
                    file::String = "", ext::String = ".$type", skip_ext::Bool = false) :: String
  asset_path(host = ac.host, package = ac.package, version = ac.version, type = type, path = path, file = file, ext = ext, skip_ext = skip_ext)
end


"""
    asset_file(...) :: String

Generates the file system path to an asset file.
"""
function asset_file(; cwd = "", file::String, path::String = "", type::String = "$(split(file, '.')[end])",
                      ext::String = "$(endswith(file, type) ? "" : ".$type")", min::Bool = false, skip_ext::Bool = false) :: String
  joinpath((filter([cwd, "assets", type, path, file*(min ? ".min" : "")*(skip_ext ? "" : ext)]) do part
    ! isempty(part)
  end)...) |> normpath
end


"""
    include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol}) :: String

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. The `file_name` should not include the extension.
"""
function include_asset(asset_type::Union{String,Symbol}, file_name::Union{String,Symbol}; min::Bool = false) :: String
  asset_path(type = string(asset_type), file = string(file_name); min)
end


"""
    css_asset(file_name::String) :: String

Path to a css asset. The `file_name` should not include the extension.
"""
function css_asset(file_name::String; min::Bool = false) :: String
  include_asset(:css, file_name; min)
end
const css = css_asset


"""
    js_asset(file_name::String) :: String

Path to a js asset. `file_name` should not include the extension.
"""
function js_asset(file_name::String; min::Bool = false) :: String
  include_asset(:js, file_name; min)
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
  Genie.Settings = $(settings);
  """
end


"""
    embeded(path::String) :: String

Reads and outputs the file at `path` within Genie's root package dir
"""
function embedded(path::String) :: String
  read(joinpath(path) |> normpath, String)
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
  string(js_settings(channel), embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), type="js", file="channels")))
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
  endpoint = Genie.Assets.asset_path(assets_config, :js, file=Genie.config.webchannels_js_file, path=channel, skip_ext = true)

  if ! external_assets()
    Router.route(endpoint) do
      Genie.Renderer.Js.js(channels(channel))
    end
  end

  channels_subscribe(channel)

  if ! external_assets()
    Genie.Renderer.Html.script(src = endpoint)
  else
    Genie.Renderer.Html.script([channels(channel)])
  end
end


########


"""
    webthreads() :: String

Outputs the webthreads.js file included with the Genie package
"""
function webthreads(channel::String = Genie.config.webthreads_default_route) :: String
  string(js_settings(channel),
          embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), file="pollymer.js")),
          embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), file="webthreads.js")))
end


"""
    webthreads_script() :: String

Outputs the channels JavaScript content within `<script>...</script>` tags, for embedding into the page.
"""
function webthreads_script(channel::String = Genie.config.webthreads_default_route) :: String
"""
<script>
$(webthreads(channel))
</script>
"""
end


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
    webthreads_support(channel = Genie.config.webthreads_default_route) :: String

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function webthreads_support(channel::String = Genie.config.webthreads_default_route) :: String
  endpoint = Genie.Assets.asset_path(assets_config, :js, file=Genie.config.webthreads_js_file, path=channel)

  if ! external_assets()
    Router.route(endpoint) do
      Genie.Renderer.Js.js(webthreads(channel))
    end
  end

  webthreads_subscribe(channel)
  webthreads_push_pull(channel)

  if ! external_assets()
    Genie.Renderer.Html.script(src="$(Genie.config.base_path)$(endpoint[2:end])")
  else
    Genie.Renderer.Html.script([webthreads(channel)])
  end
end


#######


"""
    favicon_support() :: String

Outputs the `<link>` tag for referencing the favicon file embedded with Genie.
"""
function favicon_support() :: String
  Router.route("/favicon.ico") do
    Genie.Renderer.respond(
      Genie.Renderer.WebRenderable(
        body = embedded(joinpath(@__DIR__, "..", "files", "new_app", "public", "favicon.ico") |> normpath |> abspath),
        content_type = :favicon
      )
    )
  end

  "<link rel=\"icon\" type=\"image/x-icon\" href=\"$(Genie.config.base_path)/favicon.ico\" />"
end

end
