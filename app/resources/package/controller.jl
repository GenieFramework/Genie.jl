type PackageController <: JinnieController
end

index(_::PackageController, req) = "[Cool, welcome! Search for some packages!] [search]" 