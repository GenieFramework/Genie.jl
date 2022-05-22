push!(LOAD_PATH,"../src/")

using Documenter

using Genie, Genie.App, Genie.AppServer, Genie.Assets
using Genie.Cache, Genie.Commands, Genie.Configuration, Genie.Cookies
using Genie.Deploy, Genie.Encryption, Genie.Exceptions
using Genie.FileTemplates, Genie.Flash, Genie.Generator
using Genie.Headers, Genie.HTTPUtils, Genie.Input, Genie.Plugins
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
        "Guides" => [
          "Working with Genie Apps" => "guides/Working_With_Genie_Apps.md",
          "Using Genie in an interactive environment" => "guides/Interactive_environment.md",
          "Developing an API backend" => "guides/Simple_API_backend.md",
          "Using Genie Plugins" => "guides/Genie_Plugins.md",
          "Working With Genie Apps: Intermediate Topics [WIP]" => "guides/Working_With_Genie_Apps_Intermediary_Topics.md"
        ],
        "Tutorials" => [
          "Welcome to Genie"  => "tutorials/1--Overview.md",
          "Installing Genie"  => "tutorials/2--Installing_Genie.md",
          "Getting started"   => "tutorials/3--Getting_Started.md",
          "Creating a web service" => "tutorials/4--Developing_Web_Services.md",
          "Developing MVC web applications" => "tutorials/4-1--Developing_MVC_Web_Apps.md",
          "Handling URI/query params" => "tutorials/5--Handling_Query_Params.md",
          "Working with forms and POST payloads" => "tutorials/6--Working_with_POST_Payloads.md",
          "Using JSON payloads" => "tutorials/7--Using_JSON_Payloads.md",
          "Uploading files" => "tutorials/8--Handling_File_Uploads.md",
          "Adding your libraries into Genie" => "tutorials/9--Publishing_Your_Julia_Code_Online_With_Genie_Apps.md",
          "Loading and starting Genie apps" => "tutorials/10--Loading_Genie_Apps.md",
          "Managing Genie app's dependencies" => "tutorials/11--Managing_External_Packages.md",
          "Advanced routing" => "tutorials/12--Advanced_Routing_Techniques.md",
          "Auto-loading configuration code with initializers" => "tutorials/13--Initializers.md",
          "The secrets file" => "tutorials/14--The_Secrets_File.md",
          "Auto-loading user libraries" => "tutorials/15--The_Lib_Folder.md",
          "Using Genie with Docker" => "tutorials/16--Using_Genie_With_Docker.md",
          "Working with WebSockets" => "tutorials/17--Working_with_Web_Sockets.md",
          "Force compiling route handlers" => "tutorials/80--Force_Compiling_Routes.md",
          "Deploying to Heroku with Buildpacks" => "tutorials/90--Deploying_With_Heroku_Buildpacks.md",
          "Deploying to Heroku with Docker" => "tutorials/91--Deploying_Genie_Docker_Apps_on_Heroku.md",
          "Deploying to server with Nginx" => "tutorials/92--Deploying_Genie_Server_Apps_with_Nginx.md"
        ],
        "API" => [
          "App" => "api/app.md",
          "AppServer" => "api/appserver.md",
          "Assets" => "api/assets.md",
          "Cache" => "api/cache.md",
          "Commands" => "api/commands.md",
          "Configuration" => "api/configuration.md",
          "Cookies" => "api/cookies.md",
          "Deploy" => [
            "Docker" => "api/deploy-docker.md",
            "Heroku" => "api/deploy-heroku.md"
          ],
          "Encryption" => "api/encryption.md",
          "Exceptions" => "api/exceptions.md",
          "FileTemplates" => "api/filetemplates.md",
          "Flash" => "api/flash.md",
          "Generator" => "api/generator.md",
          "Genie" => "api/genie.md",
          "Headers" => "api/headers.md",
          "HttpUtils" => "api/httputils.md",
          "Input" => "api/input.md",
          "Plugins" => "api/plugins.md",
          "Renderer" => "api/renderer.md",
          "HTML Renderer" => "api/renderer-html.md",
          "JS Renderer" => "api/renderer-js.md",
          "JSON Renderer" => "api/renderer-json.md",
          "Requests" => "api/requests.md",
          "Responses" => "api/responses.md",
          "Router" => "api/router.md",
          "Sessions" => "api/sessions.md",
          "Toolbox" => "api/toolbox.md",
          "Util" => "api/util.md",
          "WebChannels" => "api/webchannels.md"
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/Genie.jl.git",
)
