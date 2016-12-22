module AdminController
using Authentication

const before_action = [Symbol("AdminController.require_authentication")]

function require_authentication(params::Dict{Symbol,Any})
  ! Authentication.is_authenticated(params) && return (false, unauthorized_access(params))
end

include("modules/Articles.jl")
include("modules/Categories.jl")

end