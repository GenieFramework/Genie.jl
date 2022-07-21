# Customized application configuration with initializers

Initializers are plain Julia files which are loaded early in the application life-cycle (before routes, controller, or models).
They are designed to implement configuration code which is used by other parts of the application (like database connections,
logging settings, etc).

Initializers should be placed within the `config/initializers/` folder and they will be automatically loaded by Genie into the app.

**If your configuration is environment dependent (like a database connection which is different between dev and prod environments),
it should be added to the corresponding `config/env/*.jl` file.**

## Best practices

* You can name the initializers as you wish (ideally a descriptive name, like `redis.jl` for connecting to a Redis DB).
* Don't use uppercase names unless you define a module (in order to respect Julia's naming practices).
* Keep your initializer files small and focused, so they serve only one purpose.
* You can add as many initializers as you need.
* Do not abuse them, they are not meant to host complex code - app logic should be in models and controllers.

## Load order

The initializers are loaded in the order they are read from the file system. If you have initializers which depend on
other initializers, this is most likely a sign that you need to refactor using a model or a library file.

---
**HEADS UP**

Library files are Julia files which provide distinct functionality and can be placed in the `lib/` folder where they are
also automatically loaded by Genie. If the `lib/` folder does not exist, you can create it yourself.

---

## Scope

All the definitions (variables, constants, functions, modules, etc) added to initializer files are loaded into your
app's module. So if your app is called `MyGenieApp`, the definitions will be available under the `MyGenieApp` module.

---
**HEADS UP**

Given that your app's name is variable, you can also access your app's module through the `Main.UserApp` constant.
So all the definitions added to initializers can also be accessed through the `Main.UserApp` module.

---

