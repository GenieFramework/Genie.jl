# test loading of module with a path relative to the project directory as fallback

using Genie
# first load via using with a project path
@using loader_using/modules/MyModule
# now test with a local path
@using modules/MyModule

