# Uncomment the code to enable SearchLight support

#=
using SearchLight, SearchLight.QueryBuilder

Core.eval(SearchLight, :(config.db_config_settings = SearchLight.Configuration.load_db_connection()))

SearchLight.Loggers.empty_log_queue()

if SearchLight.config.db_config_settings["adapter"] != nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end
=#
