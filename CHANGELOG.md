# Changelog

## v0.14 - 2019-08-21

* consolidation of the Generator API
* Genie depencencies update
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
