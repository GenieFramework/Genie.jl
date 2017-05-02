using Documenter, Genie
using App, AppServer, Authentication, Authorization
using Cache, Commands, Configuration, Cookies
using DatabaseSeeding, Error, FileTemplates, Generator
using Helpers, Inflector, Input, Logger, Macros, Migration
using Renderer, REPL, Router, Sessions, Tester, Toolbox, Util
using FileCacheAdapter, FileSessionAdapter

push!(LOAD_PATH,  "../../src",
                  "../../src/cache_adapters",
                  "../../src/session_adapters")

makedocs()
