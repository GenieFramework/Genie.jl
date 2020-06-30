push!(LOAD_PATH,"../src/")

using Documenter

using Genie, Genie.App, Genie.AppServer, Genie.Assets
using Genie.Cache, Genie.Commands, Genie.Configuration, Genie.Cookies
using Genie.Deploy, Genie.Encryption, Genie.Exceptions
using Genie.FileTemplates, Genie.Flash, Genie.Generator
using Genie.Headers, Genie.HTTPUtils, Genie.Inflector, Genie.Input, Genie.Plugins
using Genie.Renderer, Genie.Requests, Genie.Responses, Genie.Router
using Genie.Sessions, Genie.Toolbox, Genie.Util, Genie.WebChannels

push!(LOAD_PATH,  "../../src",
                  "../../src/cache_adapters",
                  "../../src/session_adapters",
                  "../../src/renderers")

makedocs(
    sitename = "Genie - The Highly Productive Julia Web Framework",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "App" => "app.md",
        "AppServer" => "appserver.md",
        "Assets" => "assets.md",
        "Cache" => "cache.md",
        "Commands" => "commands.md",
        "Configuration" => "configuration.md",
        "Cookies" => "cookies.md",
        "Deploy Docker" => "deploy_docker.md",
        "Deploy Heroku" => "deploy_heroku.md",
        "Encryption" => "encryption.md",
        "Exceptions" => "exceptions.md",
        "FileTemplates" => "filetemplates.md",
        "Flash" => "flash.md",
        "Generator" => "generator.md",
        "Genie" => "genie.md",
        "Headers" => "headers.md",
        "HttpUtils" => "httputils.md",
        "Inflector" => "inflector.md",
        "Input" => "input.md",
        "Plugins" => "plugins.md",
        "Renderer" => "renderer.md",
        "Requests" => "requests.md",
        "Responses" => "responses.md",
        "Router" => "router.md",
        "Sessions" => "sessions.md",
        "Tester" => "tester.md",
        "Toolbox" => "toolbox.md",
        "Util" => "util.md",
        "WebChannels" => "webchannels.md",
    ],
)
