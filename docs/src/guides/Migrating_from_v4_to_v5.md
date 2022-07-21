# Migrating Genie apps from v4 to v5

Genie v5 is a major update to the Genie framework that introduces many new features and improvements. These include a nimble core architecture with many previously bundled features being now moved to stand-alone packages (cache, deployment, etc), the removal of legacy code and APIs, performance refactoring, restructuring of the core framework and APIs, and many other reliability, usability and performance improvements.

## Support for Genie v4

Despite introducing breaking changes, the upgrade from Genie v4 to v5 should be quite straightforward and should not take a long time. All users are recommended to upgrade to Genie v5.

While we will not backport compatible features from Genie 5 to Genie 4, we will continue to support the v4 API for the foreseeable period of time and we will backport compatible security patches.

### Genie v4 and Julia v1.8 compatibility issue: `modules_warned_for not defined`

Due to an issue caused by the removal of some APIs in Julia 1.8, **Genie v4 apps can not run on Julia 1.8**. This results in a `LoadError: UndefVarError: modules_warned_for not defined` exception when loading a Genie v4 app on Julia 1.8 and above.

### Addressing the issue: `modules_warned_for not defined`

The obvious and immediate solution is to simply go ahead and comment out the offending line -- the exact line will depend on your specific app, but it's line 4 in `bootstrap.jl` and starts with `push!(Base.modules_warned_for, Base.PkgId`.

However, this only eliminates the source of the exception. But it's possible that the Genie v4 app will still not run on Julia 1.8 and above as is, due to the fact that the loading of resources (controllers and models) in the app no longer works. So if the app does not work, mainly due to exceptions mentioning that the app does not have some controller or model "in its dependencies", this is the reason. The only way to fix this is to upgrade to Genie v5 and update your app to support Genie v5 by following the following steps.

## Upgrade from v4 to v5

However, some of these deep changes come at the cost of breaking compatibility with older apps that were developed using Genie v4. This guide will walk you through the process of migrating a Genie app from v4 to v5. The following changes need to be made to various Genie v4 application files. Each section indicates the file that needs to be modified.

### 1. `config/secrets.jl`

In Genie v5, `Genie.secret_token!` has been moved to a dedicated module called `Secrets`, so the `config/secrets.jl` file needs to be updated to include the new module.

``` julia
Genie.Secrets.secret_token!("<your-secret-token>")
```

### 2. `config/initializers/ssl.jl`

Genie v5 completely removed the legacy `config/initializers/ssl.jl` file. This provided a crude way of setting up SSL support for local development that was limited and not reliable. In Genie v5 the recommended approach is to set up SSL at the proxy server level, for example by using Caddy, Nginx, or Apache as a reverse proxy.

So just remove the `config/initializers/ssl.jl` file.

```julia
julia> rm("config/initializers/ssl.jl")
```

### 3. `app/helpers/ViewHelper.jl`

The `output_flash` function defined in the `ViewHelper` file uses the `flash` function which relied on `Genie.Session` in Genie v4. In Genie v5, `Genie.Session` has been moved to a dedicated plugin called `GenieSession.jl`. In addition, `GenieSession.jl` is designed to support multiple backends for session storage (file system, database, etc) so we also need to add a backend, such as `GenieSessionFileSession.jl`.

If your app uses the `output_flash` function then you need to add `GenieSession.jl` as a dependency of your app and update the `ViewHelper` file to use the `GenieSession.Flash.flash` function.

```julia
module ViewHelper

using GenieSession, GenieSessionFileSession, GenieSession.Flash

export output_flash

function output_flash(flashtype::String = "danger") :: String
  flash_has_message() ? """<div class="alert alert-$flashtype alert-dismissable">$(flash())</div>""" : ""
end

end
```

If your app does not use `output_flash` then you can just remove the `ViewHelper` file.

```julia
julia> rm("app/helpers/ViewHelper.jl")
```

### 4. All references to app resources (controllers and models)

In Genie v5, the app resources such as controllers and models were accessible directly in `routes.jl` and in any other resource. For instance, let's say that we have:

* a controller called `HomeController`
* a model called `Home`
* our app (aka our project's main module) is called `WelcomeHome` (meaning that we have a file `src/WelcomeHome.jl`)

In v4 we could access them directly in `routes.jl` (or in other controllers and models) as `using HomeController, Home`.

However, in Genie v5 all the app's resources are scoped to the app's main module. So we need to update all references to the app resources to use the app's main module, meaning that in v5 we'll need `using WelcomeHome.HomeController, WelcomeHome.Home`.

We can also dynamically reference the app's main module by using `..Main.UserApp` (so `..Main.UserApp` is the same as `WelcomeHome` in our example).

### 5. `Genie.Cache`

In Genie v5, the `Genie.Cache` module has been moved to a dedicated plugin called `GenieCache.jl`. This means that all references to `Genie.Cache` need to be updated to use  `GenieCache`.

This change was made to provide a leaner Genie core, making caching features opt-in. But also to allow the independent development of the caching features, independent from Genie itself.

### 6. `Genie.Cache.FileCache`

Starting with Genie 5, the file-based caching functionality provided by `Genie.Cache.FileCache` has been moved to a dedicated plugin called `GenieCacheFileCache.jl`. This means that all references to `Genie.Cache.FileCache` need to be updated to use `GenieCacheFileCache`. The `GenieCacheFileCache` plugin is dependent on the `GenieCache` package and it extends the functionality of `GenieCache`.

In the future, additional cache backends will be released.

### 7. `Genie.Session`

As mentioned above, the `Genie.Session` module has been moved to a dedicated plugin called `GenieSession.jl`. This means that all references to `Genie.Session` need to be updated to use `GenieSession`.

This change was made to provide a leaner Genie core, making session related features opt-in. But also to allow the independent development of the session features, independent from Genie itself.

### 8. `Genie.Session.FileSession`

Starting with Genie 5, the file-based session storage provided by `Genie.Session.FileSession` has been moved to a dedicated plugin called `GenieSessionFileSession.jl`. This means that all references to `Genie.Session.FileSession` need to be updated to use `GenieSessionFileSession`. The `GenieSessionFileSession` plugin is dependent on the `GenieSession` package and it extends the functionality of `GenieSession`.

In the future, additional session storage backends will be released.

### 9. `Genie.Deploy`

Similar to `Genie.Session` and `Genie.Cache`, the `Genie.Deploy` module has been moved to a dedicated plugin called `GenieDeploy.jl`. This means that all references to `Genie.Deploy` need to be updated to use `GenieDeploy`.

### 10. `Genie.Deploy.Docker`

Starting with Genie 5, the `Docker` deployment functionality provided by `Genie.Deploy.Docker` has been moved to a dedicated plugin called `GenieDeployDocker.jl`. This means that all references to `Genie.Deploy.Docker` need to be updated to use `GenieDeployDocker`. The `GenieDeployDocker` plugin is dependent on the `GenieDeploy` package and it extends the functionality of `GenieDeploy`.

### 11. `Genie.Deploy.Heroku`

Starting with Genie 5, the `Heroku` deployment functionality provided by `Genie.Deploy.Heroku` has been moved to a dedicated plugin called `GenieDeployHeroku.jl`. This means that all references to `Genie.Deploy.Heroku` need to be updated to use `GenieDeployHeroku`. The `GenieDeployHeroku` plugin is dependent on the `GenieDeploy` package and it extends the functionality of `GenieDeploy`.

### 12. `Genie.Deploy.JuliaHub`

Starting with Genie 5, the `JuliaHub` deployment functionality provided by `Genie.Deploy.JuliaHub` has been moved to a dedicated plugin called `GenieDeployJuliaHub.jl`. This means that all references to `Genie.Deploy.JuliaHub` need to be updated to use `GenieDeployJuliaHub`. The `GenieDeployJuliaHub` plugin is dependent on the `GenieDeploy` package and it extends the functionality of `GenieDeploy`.

### 13. `Genie.App`

The `Genie.App` module has been removed in v5 and its API has been moved to the `Genie` module.

### 14. `Genie.AppServer`

The `Genie.AppServer` module has been renamed to `Genie.Server` in v5.

### 15. `Genie.Plugins`

Starting with Genie 5, the `Genie.Plugins` functionality has been moved to a dedicated plugin called `GeniePlugins.jl`. This means that all references to `Genie.Plugins` need to be updated to use `GeniePlugins`. The `GeniePlugins` plugin is dependent on the `Genie` package and it extends the functionality of `Genie`.

### 16. `Genie.new` family of functions

All the `Genie.new` functions have been moved to `Genie.Generator` in v5.

### 17. No automatic import of `Genie` in `Main` (at REPL)

Genie v4 apps would automatically import `Genie` in `Main`, so that `Genie` would be readily available at the REPL. Starting with Genie 5, this is no longer the case and at the app's REPL it's now necessary to first run `julia> using Genie`.

### 18. Other

Genie 5 also changes or removes other APIs which can be generally be considered as internal. If you find other important breaking changes that have been missed, please open an issue on the Genie GitHub repository or just edit this file and submit a PR.
