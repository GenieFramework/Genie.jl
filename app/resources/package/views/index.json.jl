JSONAPI.json_builder(
  data = JSONAPI.data(
    packages, 
    type_         = "packages", 
    id            = :id,
    attributes    = JSONAPI.attributes(
      name        = :name, 
      url         = :url
    )
  )
)