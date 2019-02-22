using Documenter, Genie
using App, AppServer
using Cache, Commands, Configuration, Cookies, WebChannels
using FileTemplates, Generator
using Helpers, Inflector, Input, Loggers
using Renderer, REPL, Router, Sessions, Tester, Toolbox, Util
using FileCacheAdapter, FileSessionAdapter, Encryption

push!(LOAD_PATH,  "../../src",
                  "../../src/cache_adapters",
                  "../../src/session_adapters")

makedocs()
