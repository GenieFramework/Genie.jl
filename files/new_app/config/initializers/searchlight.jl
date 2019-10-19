using SearchLight, SearchLight.QueryBuilder

function initialize_searchlight()
  try
    SearchLight.Configuration.load() |> SearchLight.Database.connect!
    SearchLight.load_resources()
  catch ex
    @error "Failed loading SearchLight database configuration. Please make sure you have a valid connection.yml file."
  end

  nothing
end

@async initialize_searchlight()