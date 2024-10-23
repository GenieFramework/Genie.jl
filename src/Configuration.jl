"""
Core genie configuration / settings functionality.
"""
module Configuration

import Pkg
import Dates

using Random

"""
    pkginfo(pkg::String)

Returns installed package information for `pkg`
"""
pkginfo(pkg::String) = filter(x -> x.name == pkg && x.is_direct_dep, values(Pkg.dependencies()) |> collect)

import Logging
import Genie

export isdev, isprod, istest, env, basepath
export Settings, DEV, PROD, TEST

# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

"""
    isdev()  :: Bool

Set of utility functions that return whether or not the current environment is development, production or testing.

# Examples
```julia
julia> Configuration.isdev()
true

julia> Configuration.isprod()
false
```
"""
isdev() :: Bool  = (Genie.config.app_env == DEV)


"""
    isprod() :: Bool

Set of utility functions that return whether or not the current environment is development, production or testing.

# Examples
```julia
julia> Configuration.isdev()
true

julia> Configuration.isprod()
false
```
"""
isprod()::Bool = (Genie.config.app_env == PROD)


"""
    istest() :: Bool

Set of utility functions that return whether or not the current environment is development, production or testing.

# Examples
```julia
julia> Configuration.isdev()
true

julia> Configuration.isprod()
false
```
"""
istest()::Bool = (Genie.config.app_env == TEST)


"""
    env() :: String

Returns the current Genie environment.

# Examples
```julia
julia> Configuration.env()
"dev"
```
"""
env()::String = Genie.config.app_env


"""
    buildpath() :: String

Constructs the temp dir where Genie's view files are built.
"""
buildpath()::String = Base.Filesystem.mktempdir(prefix="jl_genie_build_")


"""
    basepath(; prefix = "/") :: String

Returns the base path for the app. Optionally takes a prefix argument -- defaults to `/`.
"""
function basepath(; prefix = "/", ignore_empty = true)
  # if base_path is not set (it's empty) then don't do anything (return empty string)
  if ignore_empty && isempty(Genie.config.base_path)
    return ""
  end

  # if base_path starts with "/" but the prefix is different, then remove the "/" from base_path
  if prefix != "/" && startswith(Genie.config.base_path, "/")
    return joinpath(prefix, Genie.config.base_path[2:end])
  end

  # if base_path already starts with the prefix, then return it as it is
  if startswith(Genie.config.base_path, prefix)
    return Genie.config.base_path
  end

  # otherwise, join the prefix with the base_path
  return joinpath(prefix, Genie.config.base_path)
end

"""
    config!(; kwargs...)

Updates Genie.config using the provided keyword arguments.
"""
function config!(; kwargs...)
  for args in kwargs
    setfield!(Genie.config, args[1], args[2])
  end

  Genie.config
end


"""
    add_cors_header!(key, value)

Adds a new CORS header to the `Genie.config.cors_headers` collection as key => value pair.

# Examples
```julia
Genie.Configuration.add_cors_header!("Access-Control-Allow-Headers", "Genie-Session-Id")
```
"""
function add_cors_header!(key, value; config = Genie.config)
  key = string(key)
  value = string(value)

  if ! haskey(config.cors_headers, key)
    @warn "CORS header key $key does not exist. Creating."
    config.cors_headers[key] = value
  else
    config.cors_headers[key] = join(push!([String(strip(h)) for h in split(config.cors_headers[key], ',')], value) |> unique!, ", ")
  end

  config
end


"""
    mutable struct Settings

App configuration - sets up the app's defaults. Individual options are overwritten in the corresponding environment file.

# Arguments
- `server_port::Int`: the port for running the web server (default 8000)
- `server_host::String`: the host for running the web server (default "127.0.0.1")
- `server_document_root::String`: path to the document root (default "public/")
- `server_handle_static_files::Bool`: if `true`, Genie will also serve static files. In production, it is recommended to serve static files with a web server like Nginx.
- `server_signature::String`: Genie's signature used for tagging the HTTP responses. If empty, it will not be added.
- `app_env::String`: the environment in which the app is running (dev, test, or prod)
- `cors_headers::Dict{String,String}`: default `Access-Control-*` CORS settings
- `cors_allowed_origins::Vector{String}`: allowed origin hosts for CORS settings
- `log_level::Logging.LogLevel`: logging severity level
- `log_to_file::Bool`: if true, information will be logged to file besides REPL
- `log_requests::Bool`: if true, requests will be automatically logged
- `inflector_irregulars::Vector{Tuple{String,String}}`: additional irregular singular-plural forms to be used by the Inflector
- `run_as_server::Bool`: when true the server thread is launched synchronously to avoid that the script exits
- `websockets_server::Bool`: if true, the websocket server is also started together with the web server
- `websockets_port::Int`: the port for the websocket server (default `server_port`)
- `initializers_folder::String`: the folder where the initializers are located (default "initializers/")
- `path_config::String`: the path to the configurations folder (default "config/")
- `path_env::String`: the path to the environment files (default "<path_config>/env/")
- `path_app::String`: the path to the app files (default "app/")
- `html_parser_close_tag::String`: default " /". Can be changed to an empty string "" so the single tags would not be closed.
- `webchannels_keepalive_frequency::Int`: default `30000`. Frequency in milliseconds to send keepalive messages to webchannel/websocket to keep the connection alive. Set to `0` to disable keepalive messages.
"""
Base.@kwdef mutable struct Settings
  server_port::Int                                    = 8000 # default port for binding the web server
  server_host::String                                 = "127.0.0.1"

  server_document_root::String                        = "public"
  server_handle_static_files::Bool                    = true
  server_signature::String                            = "Genie/Julia/$VERSION"

  app_env::String                                     = DEV

  cors_headers::Dict{String,String}                   = Dict{String,String}(
                                                        "Access-Control-Allow-Origin"       => "", # ex: "*" or "http://mozilla.org"
                                                        "Access-Control-Expose-Headers"     => "", # ex: "X-My-Custom-Header, X-Another-Custom-Header"
                                                        "Access-Control-Max-Age"            => "86400", # 24 hours
                                                        "Access-Control-Allow-Credentials"  => "", # "true" or "false"
                                                        "Access-Control-Allow-Methods"      => "", # ex: "POST, GET"
                                                        "Access-Control-Allow-Headers"      => "Accept, Accept-Language, Content-Language, Content-Type", # CORS safelisted headers
                                                        )
  cors_allowed_origins::Vector{String}                = String[]

  log_level::Logging.LogLevel                         = Logging.Info
  log_to_file::Bool                                   = false
  log_requests::Bool                                  = true
  log_date_format::String                             = "yyyy-mm-dd HH:MM:SS"

  inflector_irregulars::Vector{Tuple{String,String}}  = Tuple{String,String}[]

  run_as_server::Bool                                 = false

  base_path::String                                   = ""

  websockets_server::Bool                             = false
  websockets_protocol::Union{String,Nothing}          = nothing
  websockets_port::Union{Int,Nothing}                 = nothing
  websockets_host::String                             = server_host
  websockets_exposed_port::Union{Int,Nothing}         = nothing
  websockets_exposed_host::Union{String,Nothing}      = nothing
  websockets_base_path::String                        = base_path

  initializers_folder::String                         = "initializers"

  path_config::String                                 = "config"
  path_env::String                                    = joinpath(path_config, "env")
  path_app::String                                    = "app"
  path_resources::String                              = joinpath(path_app, "resources")
  path_lib::String                                    = "lib"
  path_helpers::String                                = joinpath(path_app, "helpers")
  path_log::String                                    = "log"
  path_tasks::String                                  = "tasks"
  path_build::String                                  = "build"
  path_plugins::String                                = "plugins"
  path_initializers::String                           = joinpath(path_config, initializers_folder)
  path_db::String                                     = "db"
  path_bin::String                                    = "bin"
  path_src::String                                    = "src"

  webchannels_default_route::String                   = "____"
  webchannels_js_file::String                         = "channels.js"
  webchannels_subscribe_channel::String               = "subscribe"
  webchannels_unsubscribe_channel::String             = "unsubscribe"
  webchannels_autosubscribe::Bool                     = true
  webchannels_eval_command::String                    = ">eval:"
  webchannels_base64_marker::String                   = "base64:"
  webchannels_timeout::Int                            = 1_000
  webchannels_keepalive_frequency::Int                = 0 # 30 seconds
  webchannels_server_gone_alert_timeout::Int          = 10_000 # 10 seconds
  webchannels_connection_attempts                     = 10
  webchannels_reconnect_delay                         = 500 # milliseconds
  webchannels_subscription_trails                     = 4

  webthreads_default_route::String                    = webchannels_default_route
  webthreads_js_file::String                          = "webthreads.js"
  webthreads_pull_route::String                       = "pull"
  webthreads_push_route::String                       = "push"
  webthreads_connection_threshold::Dates.Millisecond  = Dates.Millisecond(60_000) # 1 minute

  html_attributes_replacements::Dict{String,String}   = Dict("v__on!" => "v-on:")
  html_parser_close_tag::String                       = " /"
  html_parser_char_at::String                         = "!!"
  html_parser_char_dot::String                        = "!"
  html_parser_char_column::String                     = "!"
  html_parser_char_dash::String                       = "__"
  html_registered_tags_only::Bool                     = false

  features_peerinfo::Bool                             = false

  format_julia_builds::Bool                           = false
  format_html_output::Bool                            = true
  format_html_indentation_string::String              = "  "

  autoload::Vector{Symbol}                            = Symbol[:initializers, :helpers, :libs, :resources, :plugins, :routes, :app]
  autoload_file::String                               = ".autoload"
  autoload_ignore_file::String                        = ".autoload_ignore"
  env_file::String                                    = ".env"

  watch::Bool                                         = false
  watch_extensions::Vector{String}                    = String["jl", "html", "md", "js", "css"]
  watch_handlers::Dict{Any,Vector{Function}}          = Dict()
  watch_frequency::Int                                = 2_000 # 2 seconds
  watch_exceptions::Vector{String}                    = String["bin/", "build/", "sessions/", "Project.toml", "Manifest.toml"]

  cdn_enabled::Bool                                   = true # if true, the CDN will be used for static assets in prod mode
  cdn_url::String                                     = "https://cdn.statically.io/gh/GenieFramework" # the URL of the CDN
end

end
