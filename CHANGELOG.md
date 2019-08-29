# Changelog

## v0.16.1 - 2019-08-29

* environment configuration files define appropriate `global_logger`
* fixed issue with webserver port env settings being overwritten
* small changes to better support logging
* moved version and env info out of app files into core files

## v0.16.0 - 2019-08-29

* switched to native Julia logging (automatic logging to file for now is disabled, will come back in a future version)
* the `log` function has been removed (**breaking**)
* added support for embedded Julia within HTML arguments
* cleaned up HTML rendering
* refactored cache adapters loading to be less hacky and more performant
* refactored session adapters loading to be less hacky and more performant
* consolidated the `Helpers` API into the `Requests` and `Sessions` modules and removed `Helpers` module (**breaking**)
* added new `Exceptions` module defining the `ExceptionalResponse` type
* added extra `@params` pointing to the currently matched route and webchannel
* fixed broken `Cookies` and `Session` functionality
* `Renderer.redirect` now supports extra arguments which are passed to `Router.linkto` for reverse routing
* new `Renderer.response` method specialized for `ExceptionalResponse`
* consolidated `flash` functionality in dedicated module `Flash` (**breaking**)
* added support for URI segments matching in routes
* refactored the `Route` and `Channel` types
* `ExceptionalResponses` now break the execution flow if thrown from controller hooks
* added `up()` as shortcut for `Genie.startup()` to start the web servers
* internal API consolidation
* added new generic `error-xxx.html` page template
* updated bundled JS and CSS files to newer versions

## v0.15.0 - 2019-08-22

* fixed error in `Genie.newapp()` with `dbsupport = true`
* internal API cleanup and optimisations
* fixed issue with `newresource` SearchLight integration
* SearchLight initializer code is now uncommented
* dependencies update
* `Router.tolink` and its alias `Router.linkto` throw exceptions if the route is not defined (**breaking**)
* `Router.tolink!!` and its alias `Router.linkto!!` have been removed (**breaking**)
* new method `Requests.read(HttpFile, Type{String})` which returns the content of an uploaded file as a string.

## v0.14.0 - 2019-08-21

* consolidation of the Generator API
* Genie dependencies update
* support for Julia v1.2
* removal of the `REPL` module
* CORS handling improvement (thanks @milesfrain)
* internal API cleanup and optimisations
* bug fixes
* improved documentation
* more docstrings
* removal of deprecated `env.jl` file
* updated error HTML files (thanks @Acciaiodigitale)

## v0.13.4 - 2019-08-19

* files cleanup -- removed unused, unnecessary files from Genie codebase and new app bootstrap code
* fixed `Renderer.redirect` bug
* new helper methods in `Requests`
* extended `Router` API
* new documentation about `Router`
* documentation tweaks

## v0.13.3 - 2019-08-13

* new `Configuration` field, `websocket_port` for configuring the port for web sockets connections
* changed defaults for `startup` to fully use the configuration options
* extra documentation

## v0.9.4  - 2019-06-20

* Support for plugins (`Genie.Plugins`)
* Docs for using and developing plugins
