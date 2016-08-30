module Hooks
using Genie

const BEFORE_ACTION = :before_action_hooks

function invoke_hooks(hook_type::Symbol, m::Module, params::Dict{Symbol,Any})
  if in(hook_type, names(m, true))
    println("Found it!")
  end
end

end