JSONAPI.builder(
  data = JSONAPI.elem(
    packages, :package, 
    type_         = "packages", 
    id            = :id, 
    attributes    = JSONAPI.elem(
      :package, 
      name          = :name, 
      url           = :url, 
      readme        = () -> Model.relationship_data!(package, :repo, :has_one).readme, 
      participation = () -> Model.relationship_data!(package, :repo, :has_one).participation 
    )
  ), 
  links = JSONAPI.elem(
    self = "abc"
  )
)