using Router

route(GET, "/packages", "packages#index")
route(GET, "/packages/:package_id", "packages#show")

# API v1
route(GET, "/api/v1/packages", "packages#API.V1.index", with = Dict{Symbol, Any}(:is_api => true))