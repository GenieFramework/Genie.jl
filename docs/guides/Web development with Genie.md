#Web Development with Genie

* About Genie
* Requirements
* MVC structure
* Example app - Hello World
* Generators
* Router
* Controller
* View (Flax.jl)
* Model (SearchLight.jl)
* File structure of a Genie app

##About Genie
Genie is a web framework for developing professional grade websites and applications. It is written in Julia and provides a complete toolbox for creating powerful web applications and web APIs.

##Requirements
Genie requires at least Julia v0.6.
In order to get Genie, you need to clone it:
`Pkg.clone("https://github.com/essenciary/Gennie.jl")`

##Genie's MVC structure
Genie's goal is to build on Julia's high performance and friendly syntax while providing a rich set of high level libraries for developing web products in a highly productive and enjoyable manner. Genie apps implement the Model-View-Controller (MVC) design pattern, used by many web frameworks, including Ruby on Rails, Django or Laravel.

When the client makes a request to the Genie web server (`HttpServer.jl`), the request is handled by the `Router`. The `Router` analyzes the structure of the request URL and invokes the code defined for handling the request. For complex logic, this code should stay within a function in a dedicated `Controller` module. For simple scenarios, the code for generating the response can be defined inline, in the `route` itself.

Once invoked from the `Router`, the `Controller` orchestrates the interactions between the `Model` layer, which accesses the database, and the `View` layer, which renders a response as HTML, JSON or other supported format. The executed `Controller` function (called `action` in MVC parlance) needs to return a `HttpResponse` object -- or another object that can automatically converted by Genie (like a `String`). Genie provides a multitude of helper functions for generating the `Response` objects -- so that the developers can focus on the logic of their apps instead of handling lower level communication.

##Example app 1: Hello World
Let's take an example -- a very simple "Hello world" web app. Open a Julia REPL to create our app. Let Julia know that we'll be needing the `Genie` package.
```julia
using Genie
```
Genie provides a series of generators that make setting things up simpler, avoiding the need to write boilerplate code. One such generator sets up a new app. It will automatically create the app's folder and will create the needed files -- just make sure you're in the right folder before generating the app. If you need to, you can swtich the REPL into `shell>` mode and `cd` or use Julia's own `cd(...)` function.
```julia
Genie.REPL.new_app("hello-world")
```