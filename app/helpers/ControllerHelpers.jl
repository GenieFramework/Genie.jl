module ControllerHelpers
using Genie, Helpers

export unauthorized_access

function unauthorized_access(params::Dict{Symbol,Any})
  flash("Unauthorized access", params)
  redirect_to("/login")
end

end