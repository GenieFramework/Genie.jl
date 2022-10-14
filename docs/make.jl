push!(LOAD_PATH,"../src/")

using Documenter

using Genie, Genie.Assets, Genie.Commands, Genie.Configuration, Genie.Cookies
using Genie.Encryption, Genie.Exceptions
using Genie.FileTemplates, Genie.Generator
using Genie.Headers, Genie.HTTPUtils, Genie.Input, Genie.Loader, Genie.Logger
using Genie.Renderer, Genie.Repl, Genie.Requests, Genie.Responses, Genie.Router, Genie.Secrets, Genie.Server
using Genie.Toolbox, Genie.Util, Genie.Watch, Genie.WebChannels, Genie.WebThreads

push!(LOAD_PATH,  "../../src", "../../src/renderers")

makedocs(
    sitename = "Genie - The Highly Productive Julia Web Framework",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "Guides" => [
          "Migrating Genie v4 apps to Genie v5" => "guides/Migrating_from_v4_to_v5.md",
          "Working with Genie Apps" => "guides/Working_With_Genie_Apps.md",
          "Working With Genie Apps: Intermediate Topics [WIP]" => "guides/Working_With_Genie_Apps_Intermediary_Topics.md",
          "Using Genie in an interactive environment" => "guides/Interactive_environment.md",
          "Developing an API backend" => "guides/Simple_API_backend.md",
          "Using Genie Plugins" => "guides/Genie_Plugins.md",
          "Deploying Genie Apps On AWS" => "guides/Deploying_Genie_Apps_On_AWS.md"
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
          "Deploying to Heroku with Buildpacks" => "tutorials/90--Deploying_With_Heroku_Buildpacks.md",
          "Deploying to server with Nginx" => "tutorials/92--Deploying_Genie_Server_Apps_with_Nginx.md"
        ],
        "API" => [
          "Assets" => "API/assets.md",
          "Commands" => "API/commands.md",
          "Configuration" => "API/configuration.md",
          "Cookies" => "API/cookies.md",
          "Encryption" => "API/encryption.md",
          "Exceptions" => "API/exceptions.md",
          "FileTemplates" => "API/filetemplates.md",
          "Generator" => "API/generator.md",
          "Genie" => "API/genie.md",
          "Headers" => "API/headers.md",
          "HttpUtils" => "API/httputils.md",
          "Input" => "API/input.md",
          "Loader" => "API/loader.md",
          "Logger" => "API/logger.md",
          "Renderer" => "API/renderer.md",
          "HTML Renderer" => "API/renderer-html.md",
          "JS Renderer" => "API/renderer-js.md",
          "JSON Renderer" => "API/renderer-json.md",
          "Requests" => "API/requests.md",
          "Responses" => "API/responses.md",
          "Router" => "API/router.md",
          "Secrets" => "API/secrets.md",
          "Server" => "API/server.md",
          "Toolbox" => "API/toolbox.md",
          "Util" => "API/util.md",
          "Watch" => "API/watch.md",
          "WebChannels" => "API/webchannels.md",
          "WebThreads" => "API/webthreads.md"
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/Genie.jl.git",
)
