<!doctype html>
<html class="no-js" lang="en">

    {{> app/layouts/head_admin.mustache.jl }}

    <body>
        <div class="main-wrapper">
            <div class="app header-fixed sidebar-fixed" id="app">
                {{> app/layouts/header_admin.mustache.jl }}
                {{> app/layouts/sidebar_admin.mustache.jl }}
                <<article class="content dashboard-page">
                  {{{:yield}}}
                </article>
                <footer class="footer">
                    <div class="footer-block buttons">
                    </div>
                </footer>
            </div>
        </div>
        <script src="/js/admin/vendor.js"></script>
        <script src="/js/admin/app.js"></script>
    </body>

</html>