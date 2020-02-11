using SearchLight

SearchLight.Configuration.load()
eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
SearchLight.connect()