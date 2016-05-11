using Router

route(GET, "/api/v1/packages/search", "packages#API.V1.search", with = Dict{Symbol, Any}(:is_api => true))
route(GET, "/api/v1/packages/:package_id", "packages#API.V1.show", with = Dict{Symbol, Any}(:is_api => true))