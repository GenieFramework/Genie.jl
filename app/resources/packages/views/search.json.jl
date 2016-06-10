JSONAPI.builder(
  data = JSONAPI.elem(
    packages, :package, 
    type_         = "packages", 
    id            = ()-> Util.expand_nullable(package.id), 
    attributes    = JSONAPI.elem(
      name          = ()-> package.name, 
      url           = ()-> package.url
    ), 
    search = JSONAPI.elem(
      rank      = ()-> search_results[package.id |> Util.expand_nullable][:rank], 
      headline  = ()-> search_results[package.id |> Util.expand_nullable][:headline]
    ), 
    links = JSONAPI.elem(
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  ), 
  links = JSONAPI.pagination("/api/v1/packages/search", total_items, current_page = current_page, page_size = page_size)
)