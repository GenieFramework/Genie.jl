# Adding your existing Julia code into Genie apps

If you have existing Julia code (modules and files) which you'd like to quickly integrate into a web app, Genie provides
an easy way to add and load your code.

## Adding your Julia code to the `lib/` folder

If you have some Julia code which you'd like to integrate in a Genie app, the simplest thing is to add the files to the
`lib/` folder. The files (and folders) in the `lib/` folder are automatically loaded by Genie _recursively_. This means
that you can also add folders under `lib/`, and they will be recursively loaded (included) into the app.
Beware though that this only happens when the Genie app is initially loaded. Hence, an app restart will be required if
you add files and folders after the app is started.

---
**HEADS UP**

Genie won't create the `lib/` folder by default. If the `lib/` folder is not present in the root of the app,
just create it yourself:

```julia
julia> mkdir("lib")
```

---

Once your code is added to the `lib/` folder, it will become available in your app's environment. For example, say we
have a file called `lib/MyLib.jl`:

```julia
# lib/MyLib.jl
module MyLib

using Dates

function isitfriday()
  Dates.dayofweek(Dates.now()) == Dates.Friday
end

end
```

Assuming that the name of your Genie app (which is also the name of your main module in `src/`) is `MyGenieApp`, the
modules loaded from `lib/` will be available under the `MyGenieApp` namespace as `MyGenieApp.MyLib`.

---
**HEADS UP**

Instead of using the actual Genie app (main module) name, we can also use the alias `..Main.UserApp`.

---

So we can reference and use our modules in `lib/` in `routes.jl` as follows:

```julia
# routes.jl
using Genie
using MyGenieApp.MyLib # or using ..Main.UserApp.MyLib

route("/friday") do
  MyLib.isitfriday() ? "Yes, it's Friday!" : "No, not yet :("
end
```

Use the `lib/` folder to host your Julia code so that Genie knows where to look in order to load it and make it
available throughout the application.
