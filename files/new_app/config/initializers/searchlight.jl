# Uncomment the code to enable SearchLight support

#=
using SearchLight, SearchLight.QueryBuilder

Core.eval(SearchLight, :(config.db_config_settings = SearchLight.Configuration.load_db_connection()))

SearchLight.Loggers.setup_loggers()
SearchLight.Loggers.empty_log_queue()

if SearchLight.config.db_config_settings["adapter"] != nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end

Core.eval(Genie.Generator, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.Tester, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.Commands, :(using SearchLight, SearchLight.Migration))
Core.eval(Genie.REPL, :(using SearchLight, SearchLight.Generator, SearchLight.Migration))
=#
