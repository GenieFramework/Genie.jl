using SearchLight

try
  SearchLight.Configuration.load()

  if SearchLight.config.db_config_settings["adapter"] !== nothing
    eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
    SearchLight.connect()
  end
catch ex
  @error ex
end