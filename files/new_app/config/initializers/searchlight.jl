using SearchLight

try
  SearchLight.Configuration.load()

  if !isnothing(SearchLight.config.db_config_settings["adapter"])
    eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
    SearchLight.connect()
  end
catch ex
  @error ex
end