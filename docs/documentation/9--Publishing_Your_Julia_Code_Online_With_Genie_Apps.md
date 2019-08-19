# Publish your Julia code online with Genie apps

If you have existing Julia code (modules and libraries) which you'd like to quicly expose on the web without building an app from scratch, Genie provides an easy way to add and load your code into an app.

## Adding your Julia code to a Genie app

If you have an existing Julia application or standalone codebase which you'd like to expose over the web through a Genie app, the simples thing is to drop the files into the `lib/` folder. The `lib/` folder is automatically added by Genie to the `LOAD_PATH`, _recursively_.

This means that can also add folders under `lib/`, and they will be recursively added to the `LOAD_PATH`. Beware though that this only happens when the Genie app is initially loaded. Hence, an app restart might be required if you add nested folders after the app is started.

---
**HEADS UP**

In most cases, Genie won't create the `lib/` folder by default. If the `lib/` folder is not present in the root of the app, just create it yourself:

```julia
julia> mkdir("lib")
```

---

Once you code is added to the `lib/` follder, it will become available in your app's environment. For example, say we have a file in `lib/MyLib.jl`:

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

Then we can reference it in `routes.jl` and expose it on the web as follows:

```julia
# routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```

Use the `lib/` folder to host your Julia code so that Genie knows where to look in order to load it and make it available throughout the application.
