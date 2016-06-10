JSONAPI.builder(
  data = JSONAPI.elem(
    type_         = "package", 
    id            = ()-> package.id |> Util.expand_nullable, 
    attributes    = JSONAPI.elem(
      name          = ()-> package.name, 
      url           = ()-> package.url, 
      readme        = ()-> Model.relationship_data!(package, Repo, RELATIONSHIP_HAS_ONE).readme, 
      participation = ()-> Model.relationship_data!(package, Repo, RELATIONSHIP_HAS_ONE).participation 
    ), 
    links = JSONAPI.elem(
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  )
)