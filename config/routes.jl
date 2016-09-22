using Router

route(GET, "/articles", "articles#ArticlesController.Website.index", named = :articles_list)
route(GET, "/articles/search", "articles#ArticlesController.Website.search")

route(GET, "/articles/:article_id::Int", "articles#ArticlesController.Website.show", named = :article_show)
route(GET, "/articles/:article_slug::AbstractString", "articles#ArticlesController.Website.show", named = :article_show_by_name)

route(GET, "/admin/dashboard", "dashboard#DashboardController.index")

route(GET, "/admin/articles", "articles#AdminController.Website.articles", named = :admin_article_list)
route(GET, "/admin/articles/new", "articles#AdminController.Website.article_new", named = :admin_article_new)
route(POST, "/admin/articles/create", "articles#AdminController.Website.article_create", named = :admin_article_create)

route(GET, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_edit", named = :admin_article_edit)
route(POST, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_update", named = :admin_article_update)

route(GET, "/admin/articles/:article_id::Int/publish", "articles#AdminController.Website.article_publish", named = :admin_article_publish)
route(GET, "/admin/articles/:article_id::Int/preview", "articles#AdminController.Website.article_preview", named = :admin_article_preview)

route(GET, "/login", "user_sessions#UserSessionsController.login")
route(POST, "/login", "user_sessions#UserSessionsController.create")

route(GET, "/logout", "user_sessions#UserSessionsController.logout")