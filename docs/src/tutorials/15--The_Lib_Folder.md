# The `lib/` folder

Genie makes it easy to automatically load Julia code (modules, files, etc) into an app, outside of the standard Genie
MVC app structure. You simply need to add your files and folders into the `lib/` folder.

---
**HEADS UP**

* If the `lib/` folder does not exist, just create it yourself: `julia> mkdir("lib")`
* Genie includes the files placed within the `lib/` folder and subfolders _recursively_
* Files within `lib/` are loaded using `Revise` and are automatically reloaded if changed.

---
