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
          "Deploying to Heroku with Docker" => "tutorials/91--Deploying_Genie_Docker_Apps_on_Heroku.md"
        ],
        "API" => [
          "App" => "API/app.md",
          "AppServer" => "API/appserver.md",
          "Assets" => "API/assets.md",
          "Cache" => "API/cache.md",
          "Commands" => "API/commands.md",
          "Configuration" => "API/configuration.md",
          "Cookies" => "API/cookies.md",
          "Deploy Docker" => "API/deploy_docker.md",
          "Deploy Heroku" => "API/deploy_heroku.md",
          "Encryption" => "API/encryption.md",
          "Exceptions" => "API/exceptions.md",
          "FileTemplates" => "API/filetemplates.md",
          "Flash" => "API/flash.md",
          "Generator" => "API/generator.md",
          "Genie" => "API/genie.md",
          "Headers" => "API/headers.md",
          "HttpUtils" => "API/httputils.md",
          "Inflector" => "API/inflector.md",
          "Input" => "API/input.md",
          "Plugins" => "API/plugins.md",
          "Renderer" => "API/renderer.md",
          "HTML Renderer" => "API/renderer_html.md",
          "JS Renderer" => "API/renderer_js.md",
          "JSON Renderer" => "API/renderer_json.md",
          "Requests" => "API/requests.md",
          "Responses" => "API/responses.md",
          "Router" => "API/router.md",
          "Sessions" => "API/sessions.md",
          "Tester" => "API/tester.md",
          "Toolbox" => "API/toolbox.md",
          "Util" => "API/util.md",
          "WebChannels" => "API/webchannels.md"
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/Genie.jl.git",
)