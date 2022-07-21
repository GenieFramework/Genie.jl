# Managing external packages for your Genie app

Genie fully takes advantage of Julia's excellent package manager, `Pkg` -- while allowing Genie developers to use any
third party package available in Julia's ecosystem. This is achieved by taking a common sense approach: Genie apps are
just plain Julia projects.

In order to add extra packages to your Genie app, thus, we need to use Julia's `Pkg` features:

1. start a Genie REPL with your app: `$ bin/repl`. This will automatically load the package environment of the app.
2. switch to `Pkg` mode: `julia> ]`
3. add the package you want, for example `OhMyREPL`: `(MyGenieApp) pkg> add OhMyREPL`

That's all! Now you can use the packages at the Genie REPL or anywhere in your app via `using` or `import`.

Use the same approach to update the packages in your app, via: `pkg> up` and apply all available updates,
or `pkg> up OhMyREPL` to update a single package.
