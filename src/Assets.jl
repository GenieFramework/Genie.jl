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

function __init__()
  # make sure the assets config is properly initialized
  assets_config.host = Genie.config.base_path
  assets_config.package = "Genie.jl"
  assets_config.version = "master"
end

"""
    assets_config!(packages::Vector{Module}; config...) :: Nothing
    assets_config!(package::Module; config...) :: Nothing

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
function assets_config!(package::Module; config...) :: Nothing
  assets_config!([package]; config...)
end


"""
    assets_config!(; config...) :: Nothing

Updates the assets configuration for the current package.
"""
function assets_config!(; config...) :: Nothing
  assets_config!([@__MODULE__]; config...)
end

"""
    external_assets(host::String) :: Bool
    external_assets(ac::AssetsConfig) :: Bool
    external_assets() :: Bool

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
    asset_path(; file::String, host::String = Genie.config.base_path, package::String = "", version::String = "",
                  prefix::String = "assets", type::String = "", path::String = "", min::Bool = false,
                  ext::String = "", skip_ext::Bool = false, query::String = "") :: String
    asset_path(file::String; kwargs...) :: String
    asset_path(ac::AssetsConfig, tp::Union{Symbol,String}; type::String = string(tp), path::String = "",
                    file::String = "", ext::String = "", skip_ext::Bool = false, query::String = "") :: String

Generates the path to an asset file.
"""
function asset_path(; file::String, host::String = Genie.config.base_path, package::String = "", version::String = "",
                      prefix::String = "assets", type::String = "$(split(file, '.')[end])", path::String = "", min::Bool = false,
                      ext::String = "$(endswith(file, type) ? "" : ".$type")", skip_ext::Bool = false, query::String = "") :: String
  startswith(host, '/') && (host = host[2:end])
  endswith(host, '/') && (host = host[1:end-1])
  startswith(path, '/') && (path = path[2:end])
  endswith(path, '/') && (path = path[1:end-1])

  (
    (external_assets(host) ? "" : "/") *
    join(filter([host, package, version, prefix, type, path, file*(min ? ".min" : "")*(skip_ext ? "" : ext)]) do part
      ! isempty(part)
    end, '/') *
    query) |> lowercase
end
function asset_path(file::String; kwargs...) :: String
  asset_path(; file, kwargs...)
end
function asset_path(ac::AssetsConfig, tp::Union{Symbol,String}; type::String = string(tp), path::String = "",
                    file::String = "", ext::String = ".$type", skip_ext::Bool = false, query::String = "") :: String
  asset_path(host = ac.host, package = ac.package, version = ac.version, type = type, path = path, file = file,
              ext = ext, skip_ext = skip_ext, query = query)
end


"""
    asset_route(; file::String, package::String = "", version::String = "", prefix::String = "assets",
                  type::String = "", path::String = "", min::Bool = false,
                  ext::String = "", skip_ext::Bool = false, query::String = "") :: String
    asset_route(file::String; kwargs...) :: String
    asset_route(ac::AssetsConfig, tp::Union{Symbol,String}; type::String = string(tp), path::String = "",
                file::String = "", ext::String = "", skip_ext::Bool = false, query::String = "") :: String

Generates the route to an asset file.
"""
function asset_route(; file::String, package::String = "", version::String = "", prefix::String = "assets",
                      type::String = "$(split(file, '.')[end])", path::String = "", min::Bool = false,
                      ext::String = "$(endswith(file, type) ? "" : ".$type")", skip_ext::Bool = false, query::String = "") :: String
  startswith(path, '/') && (path = path[2:end])
  endswith(path, '/') && (path = path[1:end-1])

  ('/' *
    join(filter([package, version, prefix, type, path, file*(min ? ".min" : "")*(skip_ext ? "" : ext)]) do part
      ! isempty(part)
    end, '/') *
    query) |> lowercase
end
function asset_route(file::String; kwargs...) :: String
  asset_route(; file, kwargs...)
end
function asset_route(ac::AssetsConfig, tp::Union{Symbol,String}; type::String = string(tp), path::String = "",
                    file::String = "", ext::String = ".$type", skip_ext::Bool = false, query::String = "") :: String
  asset_route(package = ac.package, version = ac.version, type = type, path = path, file = file,
              ext = ext, skip_ext = skip_ext, query = query)
end


"""
    asset_file(; cwd = "", file::String, path::String = "", type::String = "", prefix::String = "assets",
                  ext::String = "", min::Bool = false, skip_ext::Bool = false) :: String

Generates the file system path to an asset file.
"""
function asset_file(; cwd = "", file::String, path::String = "", type::String = "$(split(file, '.')[end])", prefix::String = "assets",
                      ext::String = "$(endswith(file, type) ? "" : ".$type")", min::Bool = false, skip_ext::Bool = false) :: String
  joinpath((filter([cwd, prefix, type, path, file*(min ? ".min" : "")*(skip_ext ? "" : ext)]) do part
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


const js_literal = ["js:|", "|_"]
function jsliteral(val) :: String
  "$(js_literal[1])$val$(js_literal[2])"
end

"""
    js_settings(channel::String = Genie.config.webchannels_default_route) :: String

Sets up a `window.Genie.Settings` JavaScript object which exposes relevant Genie app settings from `Genie.config`
"""
function js_settings(channel::String = Genie.config.webchannels_default_route) :: String
  settings = Json.JSONParser.json(Dict(
    :server_host                      => Genie.config.server_host,
    :server_port                      => Genie.config.server_port,

    :websockets_protocol              => Genie.config.websockets_protocol === nothing ? jsliteral("window.location.protocol.replace('http', 'ws')") : Genie.config.websockets_protocol,
    :websockets_host                  => Genie.config.websockets_host,
    :websockets_exposed_host          => Genie.config.websockets_exposed_host === nothing ? jsliteral("window.location.hostname") : Genie.config.websockets_exposed_host,
    :websockets_port                  => Genie.config.websockets_port,
    :websockets_exposed_port          => Genie.config.websockets_exposed_port === nothing ? jsliteral("window.location.port") : Genie.config.websockets_exposed_port,
    :websockets_base_path             => Genie.config.websockets_base_path,

    :webchannels_default_route        => channel,
    :webchannels_subscribe_channel    => Genie.config.webchannels_subscribe_channel,
    :webchannels_unsubscribe_channel  => Genie.config.webchannels_unsubscribe_channel,
    :webchannels_autosubscribe        => Genie.config.webchannels_autosubscribe,
    :webchannels_eval_command         => Genie.config.webchannels_eval_command,
    :webchannels_timeout              => Genie.config.webchannels_timeout,
    :webchannels_keepalive_frequency  => Genie.config.webchannels_keepalive_frequency,
    :webchannels_server_gone_alert_timeout => Genie.config.webchannels_server_gone_alert_timeout,
    :webchannels_connection_wait_attempts => Genie.config.webchannels_connection_wait_attempts,
    :webchannels_reconnect_delay     => Genie.config.webchannels_reconnect_delay,
    :webchannels_subscription_trails => Genie.config.webchannels_subscription_trails,

    :webthreads_default_route         => channel,
    :webthreads_js_file               => Genie.config.webthreads_js_file,
    :webthreads_pull_route            => Genie.config.webthreads_pull_route,
    :webthreads_push_route            => Genie.config.webthreads_push_route,

    :base_path                        => Genie.config.base_path,
    :env                              => Genie.env(),
  ))

  if contains(settings, js_literal[1])
    settings = replace(settings, "\"$(js_literal[1])"=>"")
    settings = replace(settings, "$(js_literal[2])\""=>"")
  end

  """
  window.Genie = {};
  Genie.Settings = $settings;
  """
end


"""
    embeded(path::String) :: String

Reads and outputs the file at `path`.
"""
function embedded(path::String) :: String
  read(joinpath(path) |> normpath, String)
end


"""
    embeded_path(path::String) :: String

Returns the path relative to Genie's root package dir.
"""
function embedded_path(path::String) :: String
  joinpath(@__DIR__, "..", path) |> normpath
end

"""
  add_fileroute(assets_config::Genie.Assets.AssetsConfig, filename::AbstractString;
    basedir = pwd(),
    type::Union{Nothing, String} = nothing,
    content_type::Union{Nothing, Symbol} = nothing,
    ext::Union{Nothing, String} = nothing, kwargs...)

Helper function to add a file route to the assets based on asset_config and filename.

# Example

```
add_fileroute(StippleUI.assets_config, "Sortable.min.js")
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js")
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js.map", type = "js")
add_fileroute(StippleUI.assets_config, "QSortableTree.js")

draggabletree_deps() = [
  script(src = "/stippleui.jl/master/assets/js/sortable.min.js")
  script(src = "/stippleui.jl/master/assets/js/vuedraggable.umd.min.js")
  script(src = "/stippleui.jl/master/assets/js/qsortabletree.js")
]
Stipple.DEPS[:qdraggabletree] = draggabletree_deps
```
"""
function add_fileroute(assets_config::Genie.Assets.AssetsConfig, filename::AbstractString;
  basedir = pwd(),
  type::Union{Nothing, String} = nothing,
  content_type::Union{Nothing, Symbol} = nothing,
  ext::Union{Nothing, String} = nothing, kwargs...)

  file, ex = splitext(filename)
  ext = isnothing(ext) ? ex : ext
  type = isnothing(type) ? ex[2:end] : type

  content_type = isnothing(content_type) ? if type == "js"
    :javascript
  elseif type == "css"
    :css
  elseif type in ["jpg", "jpeg", "svg", "mov", "avi", "png", "gif", "tif", "tiff"]
    imagetype = replace(type, Dict("jpg" => "jpeg", "mpg" => "mpeg", "tif" => "tiff")...)
    Symbol("image/$imagetype")
  else
    Symbol("*.*")
  end : content_type

  Genie.Router.route(Genie.Assets.asset_path(assets_config, type; file, ext, kwargs...)) do
    Genie.Renderer.WebRenderable(
      Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; type, file)),
    content_type) |> Genie.Renderer.respond
  end
end

"""
    channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String

Outputs the `channels.js` file included with the Genie package.
"""
function channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String
  string(js_settings(channel), embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), type = "js", file = "channels")))
end


"""
    channels_script(channel::AbstractString = Genie.config.webchannels_default_route) :: String

Outputs the channels JavaScript content within `<script>...</script>` tags, for embedding into the page.
"""
function channels_script(channel::AbstractString = Genie.config.webchannels_default_route) :: String
"""
<script>
$(channels(channel))
</script>
"""
end


"""
    channels_subscribe(channel::AbstractString = Genie.config.webchannels_default_route) :: Nothing

Registers subscription and unsubscription channels for `channel`.
"""
function channels_subscribe(channel::AbstractString = Genie.config.webchannels_default_route) :: Nothing
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


function assets_endpoint(f::Function = Genie.Assets.asset_path) :: String
  f(assets_config, :js, file = Genie.config.webchannels_js_file, skip_ext = true)
end


function channels_route(channel::AbstractString = Genie.config.webchannels_default_route) :: Nothing
  if ! external_assets()
    Router.route(assets_endpoint(Genie.Assets.asset_route)) do
      Genie.Renderer.Js.js(channels(channel))
    end
  end

  nothing
end


function channels_script_tag(channel::AbstractString = Genie.config.webchannels_default_route) :: String
  if ! external_assets()
    Genie.Renderer.Html.script(src = assets_endpoint())
  else
    Genie.Renderer.Html.script([channels(channel)])
  end
end


"""
    channels_support(channel = Genie.config.webchannels_default_route) :: String

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function channels_support(channel::AbstractString = Genie.config.webchannels_default_route) :: String
  channels_route(channel)
  channels_subscribe(channel)
  channels_script_tag(channel)
end


######## WEB THREADS


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


"""
    function webthreads_subscribe(channel) :: Nothing

Registers subscription and unsubscription routes for `channel`.
"""
function webthreads_subscribe(channel::String = Genie.config.webthreads_default_route) :: Nothing
  Router.route("/$(channel)/$(Genie.config.webchannels_subscribe_channel)", method = Router.GET) do
    WebThreads.subscribe(Genie.Requests.wtclient(), channel)

    "Subscription: OK"
  end

  Router.route("/$(channel)/$(Genie.config.webchannels_unsubscribe_channel)", method = Router.GET) do
    WebThreads.unsubscribe(Genie.Requests.wtclient(), channel)
    WebThreads.unsubscribe_disconnected_clients()

    "Unsubscription: OK"
  end

  nothing
end


"""
    function webthreads_push_pull(channel) :: Nothing

Registers push and pull routes for `channel`.
"""
function webthreads_push_pull(channel::String = Genie.config.webthreads_default_route) :: Nothing
  Router.route("/$(channel)/$(Genie.config.webthreads_pull_route)", method = Router.POST) do
    WebThreads.pull(Genie.Requests.wtclient(), channel)
  end

  Router.route("/$(channel)/$(Genie.config.webthreads_push_route)", method = Router.POST) do
    WebThreads.push(Genie.Requests.wtclient(), channel, Router.params(Genie.Router.PARAMS_RAW_PAYLOAD))
  end

  nothing
end


function webthreads_endpoint(channel::String = Genie.config.webthreads_default_route) :: String
  Genie.Assets.asset_path(assets_config, :js, file = Genie.config.webthreads_js_file, path = channel, skip_ext = true)
end


function webthreads_route(channel::String = Genie.config.webthreads_default_route) :: Nothing
  if ! external_assets()
    Router.route(webthreads_endpoint(channel)) do
      Genie.Renderer.Js.js(webthreads(channel))
    end
  end

  nothing
end


function webthreads_script_tag(channel::String = Genie.config.webthreads_default_route) :: String
  if ! external_assets()
    Genie.Renderer.Html.script(src="$(Genie.config.base_path)$(webthreads_endpoint(channel)[2:end])")
  else
    Genie.Renderer.Html.script([webthreads(channel)])
  end
end


"""
    webthreads_support(channel = Genie.config.webthreads_default_route) :: String

Provides full web channels support, setting up routes for loading support JS files, web sockets subscription and
returning the `<script>` tag for including the linked JS file into the web page.
"""
function webthreads_support(channel::String = Genie.config.webthreads_default_route) :: String
  webthreads_route(channel)
  webthreads_subscribe(channel)
  webthreads_push_pull(channel)
  webthreads_script_tag(channel)
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

  "<link rel=\"icon\" type=\"image/x-icon\" href=\"$(Genie.config.base_path)$(endswith(Genie.config.base_path, '/') ? "" : "/")favicon.ico\" />"
end

end
