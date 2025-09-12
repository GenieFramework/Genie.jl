# test loading of module with a path relative to the project directory as fallback
module LoadingModule2

using Genie
@using loader_using/modules/MyModule

end