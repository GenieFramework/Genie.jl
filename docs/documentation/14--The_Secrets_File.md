# The secrets (`config/secrets.jl`) file

Confidential configuration (like API keys, usernames, passwords, etc) can be added to the `config/secrets.jl` file. This file is by default added to `.gitignore` when creating a Genie app, so it won't be added to source control.

## Scope

All the definitions (variables, constants, functions, modules, etc) added to the `secrets.jl` file are loaded into your app's module. So if your app is called `MyGenieApp`, the definitions will be available under the `MyGenieApp` module.

---
**HEADS UP**

Given the your app's name is variable, you can also access your app's module through the `UserApp` constant. So all the definitions added to `secrets.jl` can also be accessed through the `UserApp` module (`UserApp === MyGenieApp`).

---
