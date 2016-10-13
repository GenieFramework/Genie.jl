module Genie

include(abspath(joinpath("lib", "Genie", "src", "constants.jl")))

include(abspath(joinpath(ENV_PATH, ENV["GENIE_ENV"] * ".jl")))
include(abspath(joinpath(CONFIG_PATH, "app.jl")))
include(abspath(joinpath(LIB_PATH, "Genie", "src", "macros.jl")))
include(abspath(joinpath(CONFIG_PATH, "plugins.jl")))

push!(LOAD_PATH,  abspath(joinpath(LIB_PATH, "Genie", "src", "cache_adapters")),
                  abspath(joinpath(LIB_PATH, "Genie", "src", "session_adapters")),
                  abspath(joinpath(LIB_PATH, "SearchLight", "src", "database_adapters")),
                  RESOURCE_PATH, HELPERS_PATH)

include(abspath(joinpath("lib", "Genie", "src", "genie_types.jl")))

macro devtools()
  if ENV["GENIE_ENV"] == "dev"
    :(using Gallium)
  end
end

macro ifdevtools(expr::Expr)
  if ENV["GENIE_ENV"] == "dev"
    quote
      using Gallium
      $(esc(expr))
    end
  end
end

export @devtools, @ifdevtools

function startup(parsed_args = Dict{AbstractString,Any}(), start_server = false)
  isempty(parsed_args) && (parsed_args = Commands.parse_commandline_args())

  if parsed_args["s"] == "s" || start_server == true
    AppServer.startup(Genie.config.server_port)
  end

  false
end

function cache_enabled()
  Genie.config.cache_duration > 0
end

using Configuration, Logger, AppServer, Commands, App, Millboard, SearchLight, Renderer, YAML

function env_connection_data(db_settings_file::String)
  db_conn_data = YAML.load(open(db_settings_file))
  ( haskey(db_conn_data, Genie.config.app_env) ) ? db_conn_data[Genie.config.app_env] : error("DB configuration for $(Genie.config.app_env) not found")
end

function load_db_connection()
  db_settings_file = joinpath(Genie.CONFIG_PATH, Genie.GENIE_DB_CONFIG_FILE_NAME)
  isfile(abspath(db_settings_file)) && (Genie.config.db_config_settings = env_connection_data(db_settings_file))
end

load_db_connection()

include(abspath("lib/Genie/src/commands.jl"))
Commands.execute(Configuration.config)

end