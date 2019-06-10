# Uncomment the code to enable SearchLight support

#=
using SearchLight, SearchLight.QueryBuilder

SearchLight.Configuration.load()

SearchLight.Loggers.setup_loggers()
SearchLight.Loggers.empty_log_queue()

if SearchLight.config.db_config_settings["adapter"] !== nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end
=#
