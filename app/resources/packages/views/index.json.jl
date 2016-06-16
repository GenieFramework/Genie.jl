JSONAPI.builder(
  data = JSONAPI.elem(
    packages, :package, 
    type_         = "packages", 
    id            = ()-> Util.expand_nullable(package.id), 
    attributes    = JSONAPI.elem(
      name          = ()->  package.name, 
      url           = ()->  package.url,
      readme        = ()->  Model.relationship_data!(package, Repo, RELATIONSHIP_HAS_ONE).readme, 
      participation = ()-> Model.relationship_data!(package, Repo, RELATIONSHIP_HAS_ONE).participation 
    ),  
    links = JSONAPI.elem(
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  ), 
  links = JSONAPI.pagination("/api/v1/packages", total_items, current_page = current_page, page_size = page_size)
)