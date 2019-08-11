# Publish your Julia code online with Genie apps

If you have existing Julia code (modules and libraries) you'd like to expose online without building an app from scratch and copy-pasting your code the MVC way, Genie provides a built-in features to add and load your code into a Genie app.

## Adding your Julia code to a Genie app

If you have an existing Julia application or standalone codebase which you'd like to expose over the web through your Genie app, the easiest thing to do is to drop the files into the `lib/` folder.
The `lib/` folder is automatically added by Genie to the `LOAD_PATH`.

You can also add folders under `lib/`, they will be recursively added to `LOAD_PATH`. Beware though that this only happens when the Genie app is initially loaded.
Hence, an app restart might be required if you add nested folders once the app is loaded.

---
**HEADS UP**

In most cases, Genie won't create the `lib/` folder by default. If the `lib/` folder is not present in the root of the app, just create it yourself:

```julia
julia> mkdir("lib")
```

---

Once you module is added to `lib/` it will become available in your app's environment. For example, say we have a file `lib/MyLib.jl`:

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

Then we can reference it in `routes.jl` as follows:

```julia
# routes.jl
using Genie.Router
using MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```

By placing your files into the `lib/` folder, Genie knows where to look in order to load it and make it available throughout the app.
