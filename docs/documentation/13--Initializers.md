# Customized application configuration with initializers

Initializers are plain Julia files which are loaded early in the application cycle (before routes, controller, or models). They are designed to expose configuration code which might be needed later on in the application life cycle.

Initializers should be placed within the `config/initializers/` folder and they will be automatically loaded (included) by Genie.

**If your configuration is environment dependent (ie a database connection which is different between dev and prod), it should be added to the corresponding `config/env/*.jl` file.**

## Best practices

* You can name the initializers as you wish (ideally a descriptive name, like maybe `redis.jl`).
* Don't use uppercase names unless you define a module (in order to respect Julia's naming practices).
* Keep your initializer files small and focused, so they serve only one purpose.
* You can add as many initializers as you need.
* Do not abuse them, they are not meant to host complex code.

## Load order

The initializers are loaded in the order they are read from the file system. If you have initializers which depend on other initializers, this is most likely a sign that you need to refactor using a model or a library file.

---
**HEADS UP**

Library files are Julia files which provide distinct functionality and can be placed in the `lib/` folder where they are also automatically loaded by Genie. If the `lib/` folder does not exist, you can create it yourself.

---

## Scope

All the definitions (variables, constants, functions, modules, etc) added to initializer files are loaded into your app's module. So if your app is called `MyGenieApp`, the definitions will be available under the `MyGenieApp` module.

---
**HEADS UP**

Given that your app's name is variable, you can also access your app's module through the `UserApp` constant. So all the definitions added to initializers can also be accessed through the `UserApp` module (`UserApp === MyGenieApp`).

---

## Example

This is Genie's default initializer for loading the SearchLight ORM. Please notice that the initializers does contain database configuration information, which is defined in a dedicated, environment dependent file. The initializer simply delegates the configuration loading and setup to the SearchLight package.

```julia
using SearchLight, SearchLight.QueryBuilder

SearchLight.Configuration.load()

if SearchLight.config.db_config_settings["adapter"] !== nothing
  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()
end
```
