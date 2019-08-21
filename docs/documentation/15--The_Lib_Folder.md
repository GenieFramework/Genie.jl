# The `lib/` folder

Genie makes it very easy to automatically load your existing Julia code (modules, files, etc) into the app, outside of the standard MVC structure. You simply need to add your files and folders into the `lib/` folder.

---
**HEADS UP**

* If the `lib/` folder does not exist, just create it yourself: `julia> mkdir("lib")`
* Genie does not include the files placed within the `lib/` folder but _recursively_ adds all the folders to the `LOAD_PATH` - so you can include the files as needed.
* Files within `lib/` are not added to the `Revise` queue so they are not automatically reloaded by Genie if changed. If you make changes/add/remove files in `lib/` you need to restart the app or manually add them to be watched and reloaded by `Revise`.

---

