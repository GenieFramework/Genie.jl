JSONAPI.builder(
  data = JSONAPI.elem(
    package, :package, 
    type_         = "package", 
    id            = ()-> package.id |> Util.expand_nullable, 
    attributes    = JSONAPI.elem(
      package, 
      name          = ()-> package.name, 
      url           = ()-> package.url, 
      readme        = () -> Model.relationship_data!(package, :repo, :has_one).readme, 
      participation = () -> Model.relationship_data!(package, :repo, :has_one).participation 
    ), 
    links = JSONAPI.elem(
      package, 
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  )
)