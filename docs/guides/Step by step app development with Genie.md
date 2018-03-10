# Scaffolding our app
The first thing that we need to do is to setup the file structure of our app. Genie uses the "convention over configuration" design pattern, preferring to use sensible defaults represented by files of certain structures and in certain locations. Genie however does not require setting up these files ourselves - instead, it provides a rich set of generators for scaffolding every component of a web app.

The only requirement to get things started is installing Genie itself:
```julia
julia> using Pkg
julia> Pkg.clone("htts://github.com/essenciary/Genie.jl")
julia> using Genie
```

Now we can ask Genie to scaffold our app -- which we'll name "Chirper".
```julia
julia> Genie.REPL.new_app("chirper")
```

You'll see output in the console informing you about the status of the operation:
```julia
info: Done! New app created at /Users/adrian/Dropbox/Projects/chirper
info: Looking for dependencies
info: Checking for Flax rendering engine support
info: Finished adding dependencies
info: Starting your brand new Genie app - hang tight!
```

Once the app is ready, it will be automatically started. This means that:
* it will automatically `cd()` into the app's folder
* will load the Genie app environment
* will take you to a Genie REPL -- which is a Julia REPL, so you have all the power of Julia at your disposal
* the Genie REPL is indicated by the custom prompt `genie ❱❱`

We can check that everything worked well by starting up a server and taking it for a spin:
```julia
genie> server = AppServer.startup()
```
You can now visit `http://localhost:8000` in your browser - you will be welcomed by our very smart and helpful genie.

___

# Setting up the home page
Genie uses a route file to map web requests to functions. These functions process the request info and return the response. The route are defined within the `config/routes.jl` file. Right now, the file looks like this:
```julia
using Router

route("/") do
  Router.serve_static_file("/welcome.html")
end
```

At the top it brings the `Router` module into scope. Then it defines a `route` for the root page `/` -- which is handled by an anonymous function which calls `Router.serve_static_file`. The `serve_static_file` function returns the content of the `welcome.html` static file. This is the file we have seen when we accessed our website.

Let's replace the default Genie home page with a simple custom one. This time we'll do it the manual way so you can understand how things work - but in the future we'll use Genie's generators. We need to setup a new folder under `app/resources` -- let's call it `home`, cause it's for our _home_ page. And under `home`, add a `views` folder. You can use your file manager if you want -- I'll use Julia/Genie:
```julia
genie> mkpath("app/resources/home/views")
```

Inside views, let's add the file for our home page. Genie supports both HTML and Markdown pages. In this case, let's setup a simple markdown page called `home_page.md`:
```julia
genie> touch("app/resources/home/views/home_page.md")
```

We can now edit it:
```julia
genie> edit("app/resources/home/views/home_page.md")
```
This command will open the "home_page.md" file with your default editor. Add the following content, save the file and close the editor when done:
```markdown
# Welcome to Chirper!
Chirper is a cool website which allows you to post short public messages for the Chirper community -- and to follow other chirpers and see their messages!
```

Finally, we need to edit our routes file. We can no longer use the `serve_static_file` function because the markdown file needs to be parsed and converted into HTML. Instead, we'll call the `respond_with_html` function -- which takes at least two arguments: the name of the resource (in our case `home`, the name of the folder) and the name of the view file (in our case, `home_page`). 
