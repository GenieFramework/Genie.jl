"""
Core genie configuration / settings functionality.
"""
module Configuration

const GENIE_VERSION = v"0.13.4"

using YAML
using Genie

export isdev, isprod, istest, env
export @ifdev, @ifprod, @iftest
export cache_enabled, Settings, DEV, PROD, TEST

# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"


"""
    isdev()  :: Bool
    isprod() :: Bool
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
isdev() :: Bool  = (Genie.config.app_env == DEV)
isprod():: Bool = (Genie.config.app_env == PROD)
istest():: Bool = (Genie.config.app_env == TEST)

macro ifdev(e::Expr)
  isdev() && esc(e)
end
macro ifprod(e::Expr)
  isprod() && esc(e)
end
macro iftest(e::Expr)
  istest() && esc(e)
end


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
    cache_enabled() :: Bool

Indicates whether or not the app has caching enabled (`cache_duration > 0`).
"""
cache_enabled() :: Bool = (Genie.config.cache_duration > 0)


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
- `cache_adapter::Symbol`: cache adapter backend (default File)
- `cache_duraction::Int`: cache expiration time in seconds
- `log_level::Symbol`: logging severity level, one of :debug, :info, :warn, :error
- `log_formatted::Bool`: if true, Genie will attempt to pretty print some of the logged values
- `log_cache::Bool`: if true, caching info is logged
- `log_views::Bool`: if true, information from the view layer (template building) is logged
- `log_to_file::Bool`: if true, information will be logged to file besides REPL
- `assets_fingerprinted::Bool`: if true, asset fingerprinting is used in the asset pipeline
- `tests_force_test_env::Bool`: if true, when running tests, Genie will automatically switch the configuration to the test environment to avoid accidental coruption of dev or prod data
- `session_auto_start::Bool`: if true, a session is automatically started for each request
- `session_key_name::String`: the name of the session cookie
- `session_storage::Symbol`: the backend adapter for session storage (default File)
- `inflector_irregulars::Vector{Tuple{String,String}}`: additional irregular singular-plural forms to be used by the Inflector
- `flax_compile_templates::Bool`: if true, the view templates are compiled and persisted between requests
- `flax_autoregister_webcomponents::Bool`: automatically register custom HTML tags
- `run_as_server::Bool`: when true the server thread is launched synchronously to avoid that the script exits
- `websocket_server::Bool`: if true, the websocket server is also started together with the web server
- `renderer_default_layout_file::Symbol`: default name for the layout file (:app)
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

  cache_adapter::Symbol
  cache_duration::Int

  log_level::Symbol
  log_formatted::Bool
  log_cache::Bool
  log_views::Bool
  log_to_file::Bool

  assets_fingerprinted::Bool

  tests_force_test_env::Bool

  session_auto_start::Bool
  session_key_name::String
  session_storage::Symbol

  inflector_irregulars::Vector{Tuple{String,String}}

  flax_compile_templates::Bool
  flax_autoregister_webcomponents::Bool

  run_as_server::Bool

  websocket_server::Bool
  websocket_port::Int

  renderer_default_layout_file::Symbol

  Settings(;
            server_port                 = 8000, # default port for binding the web server
            server_host                 = "127.0.0.1",
            server_document_root        = "public",
            server_handle_static_files  = true,
            server_signature            = "Genie/$GENIE_VERSION/Julia/$VERSION",

            app_env       = ENV["GENIE_ENV"],

            cors_headers  = Dict{String,String}(
              "Access-Control-Allow-Origin"       => "", # ex: "*" or "http://mozilla.org"
              "Access-Control-Expose-Headers"     => "", # ex: "X-My-Custom-Header, X-Another-Custom-Header"
              "Access-Control-Max-Age"            => "86400", # 24 hours
              "Access-Control-Allow-Credentials"  => "", # "true" or "false"
              "Access-Control-Allow-Methods"      => "", # ex: "POST, GET"
              "Access-Control-Allow-Headers"      => "", # ex: "X-PINGOTHER, Content-Type"
            ),
            cors_allowed_origins = String[],

            cache_adapter     = :FileCacheAdapter,
            cache_duration    = 0,

            log_level     = :debug,
            log_formatted = true,
            log_cache     = true,
            log_views     = true,
            log_to_file   = false,

            assets_fingerprinted  = false,

            tests_force_test_env = true,

            session_auto_start  = false,
            session_key_name    = "__GENIESID",
            session_storage     = :File,

            inflector_irregulars = Tuple{String,String}[],

            flax_compile_templates = false,
            flax_autoregister_webcomponents = true,

            run_as_server = false,

            websocket_server = false,
            websocket_port = 8001,

            renderer_default_layout_file = :app,
        ) =
              new(
                  server_port, server_host,
                  server_document_root, server_handle_static_files, server_signature,
                  app_env,
                  cors_headers, cors_allowed_origins,
                  cache_adapter, cache_duration,
                  log_level, log_formatted, log_cache, log_views, log_to_file,
                  assets_fingerprinted,
                  tests_force_test_env,
                  session_auto_start, session_key_name, session_storage,
                  inflector_irregulars,
                  flax_compile_templates, flax_autoregister_webcomponents,
                  run_as_server,
                  websocket_server, websocket_port,
                  renderer_default_layout_file
                )
end

end
