type Package_Controller <: Jinnie_Controller
end

index(_::Package_Controller, req) = "[Cool, welcome! Search for some packages!] [search]" 

function api(_::Package_Controller, req)
  return Mux.app(req)
end