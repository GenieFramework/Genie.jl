# test loading of module with a path relative to the project directory as fallback
module LoadingModule1

using Genie
@using modules/MyModule

end