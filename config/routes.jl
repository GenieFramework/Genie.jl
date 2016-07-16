using Router

route(GET, "/articles", "articles#ArticlesController.Website.index")
route(GET, "/articles/search", "articles#ArticlesController.Website.search")
route(GET, "/articles/:article_id::Int", "articles#ArticlesController.Website.show")
route(GET, "/articles/:article_slug::AbstractString", "articles#ArticlesController.Website.show")

route(GET, "/admin/articles", "articles#ArticlesController.Website.index")
route(GET, "admin/articles/:article_id::Int", "articles#ArticlesController.Website.show")