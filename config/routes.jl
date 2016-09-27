using Router

route(GET, "/", "articles#ArticlesController.Website.index", named = :home)

route(GET, "/blog", "articles#ArticlesController.Website.index", named = :articles_list)
route(GET, "/blog/search", "articles#ArticlesController.Website.search")
route(GET, "/blog/:article_id::Int", "articles#ArticlesController.Website.show", named = :article_show)
route(GET, "/blog/:article_slug::AbstractString", "articles#ArticlesController.Website.show", named = :article_show_by_name)

route(GET, "/docs", "docs#DocsController.Website.index", named = :docs_list)
route(GET, "/docs/search", "docs#DocsController.Website.search")
route(GET, "/docs/:article_id::Int", "docs#DocsController.Website.show", named = :docs_show)
route(GET, "/docs/:article_slug::AbstractString", "docs#DocsController.Website.show", named = :docs_show_by_name)

# admin

route(GET, "/admin/dashboard", "dashboard#DashboardController.index")

route(GET, "/admin/articles", "articles#AdminController.Website.articles", named = :admin_article_list)
route(GET, "/admin/articles/new", "articles#AdminController.Website.article_new", named = :admin_article_new)
route(POST, "/admin/articles/create", "articles#AdminController.Website.article_create", named = :admin_article_create)

route(GET, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_edit", named = :admin_article_edit)
route(POST, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_update", named = :admin_article_update)

route(GET, "/admin/articles/:article_id::Int/publish", "articles#AdminController.Website.article_publish", named = :admin_article_publish)
route(GET, "/admin/articles/:article_id::Int/preview", "articles#AdminController.Website.article_preview", named = :admin_article_preview)

# login

route(GET, "/login", "user_sessions#UserSessionsController.login")
route(POST, "/login", "user_sessions#UserSessionsController.create")

route(GET, "/logout", "user_sessions#UserSessionsController.logout")
