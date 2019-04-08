"""
Core genie configuration / settings functionality.
"""
module Configuration

const GENIE_VERSION = v"0.9.0"

using Genie, YAML

export is_dev, is_prod, is_test, isdev, isprod, istest, env
export @ifdev, @ifprod, @iftest
export cache_enabled, Settings, DEV, PROD, TEST
export LOG_LEVEL_VERBOSITY_VERBOSE, LOG_LEVEL_VERBOSITY_MINIMAL

# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

# log levels
const LOG_LEVEL_VERBOSITY_VERBOSE = :verbose
const LOG_LEVEL_VERBOSITY_MINIMAL = :minimal


"""
    is_dev()  :: Bool
    is_prod() :: Bool
    is_test() :: Bool

Set of utility functions that return whether or not the current environment is development, production or testing.

# Examples
```julia
julia> Configuration.is_dev()
true

julia> Configuration.is_prod()
false
```
"""
is_dev():: Bool  = (Genie.config.app_env == DEV)
is_prod():: Bool = (Genie.config.app_env == PROD)
is_test():: Bool = (Genie.config.app_env == TEST)

const isdev  = is_dev
const isprod = is_prod
const istest = is_test

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
"""
mutable struct Settings
  server_port::Int
  server_host::String
  server_workers_count::Int
  server_document_root::String
  server_handle_static_files::Bool
  server_signature::String

  app_env::String

  cors_headers::Dict{String,String}
  cors_allowed_origins::Vector{String}

  suppress_output::Bool
  output_length::Int

  tasks_folder::String
  test_folder::String

  log_folder::String

  cache_folder::String
  cache_adapter::Symbol
  cache_duration::Int
  cache_table::String

  log_router::Bool
  log_level::Symbol
  log_verbosity::Symbol
  log_formatted::Bool
  log_cache::Bool
  log_views::Bool
  log_to_file::Bool

  assets_path::String
  assets_serve::Bool
  assets_fingerprinted::Bool

  tests_force_test_env::Bool

  session_auto_start::Bool
  session_key_name::String
  session_storage::Symbol
  session_folder::String
  session_table::String

  inflector_irregulars::Vector{Tuple{String,String}}

  html_template_engine::Symbol
  json_template_engine::Symbol

  flax_compile_templates::Bool

  lookup_ip::Bool

  run_as_server::Bool

  websocket_server::Bool

  renderer_default_layout_file::Symbol

  Settings(;
            server_port                 = 8000, # default port for binding the web server
            server_host                 = "127.0.0.1",
            server_workers_count        = 1,
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

            suppress_output = false,
            output_length   = 10_000, # where to truncate strings in console

            task_folder       = joinpath("task"),
            test_folder       = joinpath("test"),

            log_folder        = joinpath("log"),

            cache_folder      = joinpath("cache"),
            cache_adapter     = :FileCacheAdapter,
            cache_duration    = 0,
            cache_table       = "storage_caches",

            log_router    = false,
            log_level     = :debug,
            log_verbosity = LOG_LEVEL_VERBOSITY_VERBOSE,
            log_formatted = true,
            log_cache     = true,
            log_views     = true,
            log_to_file   = false,

            assets_path           = "/",
            assets_serve          = true,
            assets_fingerprinted  = false,

            tests_force_test_env = true,

            session_auto_start  = false,
            session_key_name    = "__GENIESID",
            session_storage     = :File,
            session_folder      = "session",
            session_table       = "storage_sessions",

            inflector_irregulars = Tuple{String,String}[],

            html_template_engine = :Flax,
            json_template_engine = :Flax,

            flax_compile_templates = false,

            lookup_ip = true,

            run_as_server = false,

            websocket_server = false,

            renderer_default_layout_file = :app,
        ) =
              new(
                  server_port, server_host,
                  server_workers_count, server_document_root, server_handle_static_files, server_signature,
                  app_env,
                  cors_headers, cors_allowed_origins,
                  suppress_output, output_length,
                  task_folder, test_folder,
                  log_folder,
                  cache_folder, cache_adapter, cache_duration, cache_table,
                  log_router,
                  log_level, log_verbosity, log_formatted, log_cache, log_views, log_to_file,
                  assets_path, assets_serve, assets_fingerprinted,
                  tests_force_test_env,
                  session_auto_start, session_key_name, session_storage, session_folder, session_table,
                  inflector_irregulars,
                  html_template_engine, json_template_engine,
                  flax_compile_templates,
                  lookup_ip,
                  run_as_server,
                  websocket_server,
                  renderer_default_layout_file
                )
end

end
