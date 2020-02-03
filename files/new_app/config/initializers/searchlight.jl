using SearchLight, SearchLight.QueryBuilder

function initialize_searchlight()
  try
    SearchLight.Configuration.load() |> SearchLight.connect!
  catch ex
    @error ex
  end

  nothing
end

@async initialize_searchlight()