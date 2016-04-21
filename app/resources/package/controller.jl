type PackagesController <: Jinnie.JinnieController
end

function index(p::PackagesController, params::Dict{Symbol, Any}, req::Request, res::Response) 
  "[Cool, welcome! Search for some packages!] [search]" 
end

show(_::PackagesController, params::Dict{Symbol, Any}, req::Request, res::Response) = "Check out this cool package yo!" 

module API 
module V1

using Jinnie

function index(p::Jinnie.PackagesController, params::Dict{Symbol, Any}, req::Request, res::Response) 
  packages = Model.find(Jinnie.Package, SQLQuery(limit = 20))
  ( 200, 
    Dict{AbstractString, AbstractString}("Content-Type" => "text/json"), 
    JSONAPI.json(:package, :index, packages = packages)
  )
end

end
end