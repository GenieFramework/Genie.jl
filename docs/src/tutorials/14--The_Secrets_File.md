# The secrets (`config/secrets.jl`) file

Confidential configuration data (like API keys, usernames, passwords, etc) should be added to the `config/secrets.jl` file.
This file is by default added to `.gitignore` when creating a Genie app, so it won't be added to source control --
to avoid that it is accidentally exposed.

## Scope

All the definitions (variables, constants, functions, modules, etc) added to the `secrets.jl` file are loaded into your
app's module. So if your app (and its main module) is called `MyGenieApp`, the definitions will be available under the `MyGenieApp` namespace.

---
**HEADS UP**

Given the your app's name is variable, you can also access your app's module through the `Main.UserApp` constant. So all
the definitions added to `secrets.jl` can also be accessed through the `Mani.UserApp` module.

---
