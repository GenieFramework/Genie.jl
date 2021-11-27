"""
Core genie configuration / settings functionality.
"""
module Configuration

import Pkg
import Dates

using Random

import VersionCheck

function __init__()
  try
    @async VersionCheck.newversion("Genie", url = "https://genieframework.com/CHANGELOG.html")
  catch
  end
end

"""
    pkginfo(pkg::String)

Returns installed package information for `pkg`
"""
pkginfo(pkg::String) = filter(x -> x.name == pkg && x.is_direct_dep, values(Pkg.dependencies()) |> collect)

import Logging
import Genie
import MbedTLS

export isdev, isprod, istest, env
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
buildpath() :: String = Base.Filesystem.mktempdir(prefix = "jl_genie_build_")


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
- `cache_duration::Int`: cache expiration time in seconds
- `log_level::Logging.LogLevel`: logging severity level
- `log_to_file::Bool`: if true, information will be logged to file besides REPL
- `session_key_name::String`: the name of the session cookie
- `session_storage::Symbol`: the backend adapter for session storage (default File)
- `inflector_irregulars::Vector{Tuple{String,String}}`: additional irregular singular-plural forms to be used by the Inflector
- `run_as_server::Bool`: when true the server thread is launched synchronously to avoid that the script exits
- `websockets_server::Bool`: if true, the websocket server is also started together with the web server
- `html_parser_close_tag::String`: default " /". Can be changed to an empty string "" so the single tags would not be closed.
- `ssl_enabled::Bool`: default false. Server runs over SSL/HTTPS in development.
- `ssl_config::MbedTLS.SSLConfig`: default `nothing`. If not `nothing` and `ssl_enabled`, it will use the config to start the server over HTTPS.
"""
Base.@kwdef mutable struct Settings
  server_port::Int                                    = (haskey(ENV, "PORT") ? parse(Int, ENV["PORT"]) : 8000) # default port for binding the web server
  server_host::String                                 = haskey(ENV, "HOST") ? ENV["HOST"] : "127.0.0.1"
  server_document_root::String                        = "public"
  server_handle_static_files::Bool                    = true
  server_signature::String                            = "Genie/Julia/$VERSION"

  app_env::String                                     = haskey(ENV, "GENIE_ENV") ? ENV["GENIE_ENV"] : DEV

  cors_headers::Dict{String,String}                   = Dict{String,String}(
                                                          "Access-Control-Allow-Origin"       => "", # ex: "*" or "http://mozilla.org"
                                                          "Access-Control-Expose-Headers"     => "", # ex: "X-My-Custom-Header, X-Another-Custom-Header"
                                                          "Access-Control-Max-Age"            => "86400", # 24 hours
                                                          "Access-Control-Allow-Credentials"  => "", # "true" or "false"
                                                          "Access-Control-Allow-Methods"      => "", # ex: "POST, GET"
                                                          "Access-Control-Allow-Headers"      => "", # ex: "X-PINGOTHER, Content-Type"
                                                        )
  cors_allowed_origins::Vector{String}                = String[]

  cache_duration::Int                                 = 0
  cache_storage::Union{Symbol,Nothing}                = nothing

  log_level::Logging.LogLevel                         = Logging.Debug
  log_to_file::Bool                                   = false
  log_requests::Bool                                  = true

  inflector_irregulars::Vector{Tuple{String,String}}  = Tuple{String,String}[]

  run_as_server::Bool                                 = false

  websockets_server::Bool                             = false
  websockets_port::Int                                = server_port

  initializers_folder::String                         = "initializers"

  path_config::String                                 = "config"
  path_env::String                                    = joinpath(path_config, "env")
  path_app::String                                    = "app"
  path_resources::String                              = joinpath(path_app, "resources")
  path_lib::String                                    = "lib"
  path_helpers::String                                = joinpath(path_app, "helpers")
  path_log::String                                    = "log"
  path_tasks::String                                  = "tasks"
  path_build::String                                  = buildpath()
  path_plugins::String                                = "plugins"
  path_cache::String                                  = "cache"
  path_initializers::String                           = joinpath(path_config, initializers_folder)
  path_db::String                                     = "db"
  path_bin::String                                    = "bin"
  path_src::String                                    = "src"

  webchannels_default_route::String                   = lowercase(randstring(8))
  webchannels_js_file::String                         = "channels.js"
  webchannels_subscribe_channel::String               = "subscribe"
  webchannels_unsubscribe_channel::String             = "unsubscribe"
  webchannels_autosubscribe::Bool                     = true
  webchannels_eval_command::String                    = ">eval:"
  webchannels_timeout::Int                            = 1_000

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

  ssl_enabled::Bool                                   = false
  ssl_config::Union{MbedTLS.SSLConfig,Nothing}        = nothing

  session_key_name::String                            = "__geniesid"
  session_storage::Union{Symbol,Nothing}              = nothing
  session_options::Dict{String,Any}                   = Dict{String,Any}("Path" => "/", "HttpOnly" => true, "Secure" => ssl_enabled)

  base_path::String                                   = haskey(ENV, "BASEPATH") ? ENV["BASEPATH"] : ""

  features_peerinfo::Bool                             = false

  format_julia_builds::Bool                           = true
  format_html_output::Bool                            = true
  format_html_indentation_string::String              = "  "
end

end
