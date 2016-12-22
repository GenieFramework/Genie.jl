using Router

route(GET, "/", "home#HomeController.index", named = :home)

route(GET, "/blog", "articles#ArticlesController.Website.index", named = :articles_list)
route(GET, "/blog/search", "articles#ArticlesController.Website.search")
route(GET, "/blog/:article_id::Int", "articles#ArticlesController.Website.show", named = :article_show)
route(GET, "/blog/:article_slug::AbstractString", "articles#ArticlesController.Website.show", named = :article_show_by_name)

route(GET, "/docs", "docs#DocsController.Website.index", named = :docs_list)
route(GET, "/docs/search", "docs#DocsController.Website.search")
route(GET, "/docs/:article_id::Int", "docs#DocsController.Website.show", named = :docs_show)
route(GET, "/docs/:article_slug::AbstractString", "docs#DocsController.Website.show", named = :docs_show_by_name)

# admin

route(GET, "/admin/dashboard", "dashboard#DashboardController.index", named = :admin_dashboard)

route(GET, "/admin/articles", "admin#AdminController.Articles.articles", named = :admin_article_list)
route(GET, "/admin/articles/new", "admin#AdminController.Articles.article_new", named = :admin_article_new)
route(POST, "/admin/articles/create", "admin#AdminController.Articles.article_create", named = :admin_article_create)
route(GET, "/admin/articles/:article_id::Int", "admin#AdminController.Articles.article_edit", named = :admin_article_edit)
route(POST, "/admin/articles/:article_id::Int", "admin#AdminController.Articles.article_update", named = :admin_article_update)

route(GET, "/admin/articles/:article_id::Int/publish", "admin#AdminController.Articles.article_publish", named = :admin_article_publish)
route(GET, "/admin/articles/:article_id::Int/preview", "admin#AdminController.Articles.article_preview", named = :admin_article_preview)

route(GET, "/admin/categories", "admin#AdminController.Categories.categories", named = :admin_categories_list)
route(GET, "/admin/categories/new", "admin#AdminController.Categories.category_new", named = :admin_category_new)
route(POST, "/admin/categories/create", "admin#AdminController.Categories.category_create", named = :admin_category_create)
route(GET, "/admin/categories/:category_id::Int", "admin#AdminController.Categories.category_edit", named = :admin_category_edit)
route(POST, "/admin/categories/:category_id::Int", "admin#AdminController.Categories.category_update", named = :admin_category_update)

# login

route(GET, "/login", "user_sessions#UserSessionsController.login")
route(POST, "/login", "user_sessions#UserSessionsController.create")

route(GET, "/logout", "user_sessions#UserSessionsController.logout")
