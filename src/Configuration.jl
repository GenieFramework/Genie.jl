"""
Core genie configuration / settings functionality.
"""
module Configuration

using Revise

"""
  const GENIE_VERSION

References the current Genie version number.
"""
const GENIE_VERSION = v"1.1"

import Logging
import Genie
import MbedTLS

export isdev, isprod, istest, env
export Settings, DEV, PROD, TEST

# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"


haskey(ENV, "GENIE_ENV") || (ENV["GENIE_ENV"] = DEV)
haskey(ENV, "HOST") || (ENV["HOST"] = "127.0.0.1")


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
isprod():: Bool = (Genie.config.app_env == PROD)


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
istest():: Bool = (Genie.config.app_env == TEST)


"""
    env() :: String

Returns the current Genie environment.

# Examples
```julia
julia> Configuration.env()
"dev"
```
"""
env() :: String = Genie.config.app_env


"""
    buildpath() :: String

Constructs the temp dir where Genie's view files are built.
"""
buildpath() :: String = Base.Filesystem.mktempdir(prefix = "jl_genie_build_", cleanup = false)


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
- `cache_duraction::Int`: cache expiration time in seconds
- `log_level::Logging.LogLevel`: logging severity level
- `log_to_file::Bool`: if true, information will be logged to file besides REPL
- `assets_fingerprinted::Bool`: if true, asset fingerprinting is used in the asset pipeline
- `session_key_name::String`: the name of the session cookie
- `session_storage::Symbol`: the backend adapter for session storage (default File)
- `inflector_irregulars::Vector{Tuple{String,String}}`: additional irregular singular-plural forms to be used by the Inflector
- `run_as_server::Bool`: when true the server thread is launched synchronously to avoid that the script exits
- `websockets_server::Bool`: if true, the websocket server is also started together with the web server
- `html_parser_close_tag::String`: default " /". Can be changed to an empty string "" so the single tags would not be closed.
- `ssl_enabled::Bool`: default false. Server runs over SSL/HTTPS in development.
- `ssl_config::MbedTLS.SSLConfig`: default `nothing`. If not `nothing` and `ssl_enabled`, it will use the config to start the server over HTTPS.
"""
mutable struct Settings
  server_port::Int
  server_host::String
  server_document_root::String

  server_handle_static_files::Bool
  server_signature::String

  app_env::String

  cors_headers::Dict{String,String}
  cors_allowed_origins::Vector{String}

  cache_duration::Int
  cache_storage::Symbol

  log_level::Logging.LogLevel
  log_to_file::Bool

  assets_fingerprinted::Bool

  session_key_name::String
  session_storage::Symbol

  inflector_irregulars::Vector{Tuple{String,String}}

  run_as_server::Bool

  websockets_server::Bool
  websockets_port::Int

  initializers_folder::String

  path_config::String
  path_env::String
  path_app::String
  path_resources::String
  path_lib::String
  path_helpers::String
  path_log::String
  path_tasks::String
  path_build::String
  path_plugins::String
  path_cache::String
  path_initializers::String
  path_db::String
  path_bin::String
  path_src::String

  webchannels_default_route::String
  webchannels_js_file::String
  webchannels_subscribe_channel::String
  webchannels_unsubscribe_channel::String
  webchannels_autosubscribe::Bool

  html_parser_close_tag::String
  html_parser_char_at::String
  html_parser_char_dot::String
  html_parser_char_column::String
  html_parser_char_dash::String

  ssl_enabled::Bool
  ssl_config::Union{MbedTLS.SSLConfig,Nothing}

  Settings(;
            server_port                 = (haskey(ENV, "PORT") ? parse(Int, ENV["PORT"]) : 8000), # default port for binding the web server
            server_host                 = ENV["HOST"],
            server_document_root        = "public",
            server_handle_static_files  = true,
            server_signature            = "Genie/$GENIE_VERSION/Julia/$VERSION",

            app_env                     = ENV["GENIE_ENV"],

            cors_headers  = Dict{String,String}(
              "Access-Control-Allow-Origin"       => "", # ex: "*" or "http://mozilla.org"
              "Access-Control-Expose-Headers"     => "", # ex: "X-My-Custom-Header, X-Another-Custom-Header"
              "Access-Control-Max-Age"            => "86400", # 24 hours
              "Access-Control-Allow-Credentials"  => "", # "true" or "false"
              "Access-Control-Allow-Methods"      => "", # ex: "POST, GET"
              "Access-Control-Allow-Headers"      => "", # ex: "X-PINGOTHER, Content-Type"
            ),
            cors_allowed_origins = String[],

            cache_duration    = 0,
            cache_storage     = :File,

            log_level     = Logging.Debug,
            log_to_file   = false,

            assets_fingerprinted  = false,

            session_key_name    = "__geniesid",
            session_storage     = :File,

            inflector_irregulars = Tuple{String,String}[],

            run_as_server = false,

            websockets_server = false,
            websockets_port   = server_port + 1,

            initializers_folder = "initializers",

            path_config         = "config",
            path_env            = joinpath(path_config, "env"),
            path_app            = "app",
            path_resources      = joinpath(path_app, "resources"),
            path_lib            = "lib",
            path_helpers        = joinpath(path_app, "helpers"),
            path_log            = "log",
            path_tasks          = "tasks",
            path_build          = buildpath(),
            path_plugins        = "plugins",
            path_cache          = "cache",
            path_initializers   = joinpath(path_config, initializers_folder),
            path_db             = "db",
            path_bin            = "bin",
            path_src            = "src",

            webchannels_default_route       = "__",
            webchannels_js_file             = "channels.js",
            webchannels_subscribe_channel   = "subscribe",
            webchannels_unsubscribe_channel = "unsubscribe",
            webchannels_autosubscribe       = true,

            html_parser_close_tag = " /",
            html_parser_char_at = "!!",
            html_parser_char_dot = "!",
            html_parser_char_column = "!",
            html_parser_char_dash = "__",

            ssl_enabled = false,
            ssl_config = nothing
        ) =
              new(
                  server_port, server_host,
                  server_document_root, server_handle_static_files, server_signature,
                  app_env,
                  cors_headers, cors_allowed_origins,
                  cache_duration, cache_storage,
                  log_level, log_to_file,
                  assets_fingerprinted,
                  session_key_name, session_storage,
                  inflector_irregulars,
                  run_as_server,
                  websockets_server, websockets_port,
                  initializers_folder,
                  path_config, path_env, path_app, path_resources, path_lib, path_helpers, path_log, path_tasks, path_build,
                  path_plugins, path_cache, path_initializers, path_db, path_bin, path_src,
                  webchannels_default_route, webchannels_js_file, webchannels_subscribe_channel, webchannels_unsubscribe_channel, webchannels_autosubscribe,
                  html_parser_close_tag, html_parser_char_at, html_parser_char_dot, html_parser_char_column, html_parser_char_dash,
                  ssl_enabled, ssl_config
                )
end

end
