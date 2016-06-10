using Router

# API
route(GET, "/api/v1/packages", "packages#PackagesController.API.V1.index", with = Dict{Symbol, Any}(:is_api => true))
route(GET, "/api/v1/packages/search", "packages#PackagesController.API.V1.search", with = Dict{Symbol, Any}(:is_api => true))
route(GET, "/api/v1/packages/:package_id", "packages#PackagesController.API.V1.show", with = Dict{Symbol, Any}(:is_api => true))

# web app
route(GET, "/packages", "packages#PackagesController.index", with = Dict{Symbol, Any}(:is_api => true))