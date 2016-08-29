using Router

route(GET, "/articles", "articles#ArticlesController.Website.index", named = :articles_list)
route(GET, "/articles/search", "articles#ArticlesController.Website.search")
route(GET, "/articles/:article_id::Int", "articles#ArticlesController.Website.show", named = :article_show)
route(GET, "/articles/:article_slug::AbstractString", "articles#ArticlesController.Website.show", named = :article_show_by_name)

route(GET, "/admin/dashboard", "dashboard#DashboardController.index")

route(GET, "/admin/articles", "articles#AdminController.Website.articles", named = :admin_articles_list)

route(GET, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_edit", named = :admin_article_edit)
route(POST, "/admin/articles/:article_id::Int", "articles#AdminController.Website.article_update", named = :admin_article_update)

route(GET, "/login", "user_sessions#UserSessionsController.login")
route(POST, "/login", "user_sessions#UserSessionsController.create")

route(GET, "/logout", "user_sessions#UserSessionsController.logout")