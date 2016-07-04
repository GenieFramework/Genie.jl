using Router

# API
route(GET, "/api/v1/packages", "packages#PackagesController.API.V1.index")
route(GET, "/api/v1/packages/search", "packages#PackagesController.API.V1.search")
route(GET, "/api/v1/packages/:package_id", "packages#PackagesController.API.V1.show")

# web app
route(GET, "/packages", "packages#PackagesController.Website.index")
route(GET, "/packages/search", "packages#PackagesController.Website.search")
route(GET, "/packages/:package_id", "packages#PackagesController.Website.show")