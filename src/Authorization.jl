"""
Deals with authorization functionality, roles, ACL.
"""
module Authorization

using Genie, SearchLight, Authentication, Helpers, App, Util, Loggers

export is_authorized, with_authorization


"""
    is_authorized(ability::Symbol, params::Dict{Symbol,Any}) :: Bool

Checks if the user authenticated on the current session (its role) is authorized for `ability` per the corresponding access list.
"""
function is_authorized(ability::Symbol, params::Dict{Symbol,Any}) :: Bool
  Authentication.is_authenticated(session(params)) || return false
  user_role = expand_nullable(expand_nullable(current_user(session(params)), User()).role, :user)
  role_has_ability(user_role, ability, params)
end


"""
    with_authorization(f::Function, ability::Symbol, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` if the user authenticatedon the current session is authorized for `ability` - otherwise `fallback` is invoked.
"""
function with_authorization(f::Function, ability::Symbol, fallback::Function, params::Dict{Symbol,Any})
  if ! is_authorized(ability, params)
    fallback(params)
  else
    user_role = expand_nullable( expand_nullable(current_user(session(params)), User()).role, :user )
    f(scopes_of_role_ability(user_role, ability, params))
  end
end


"""
    role_has_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Bool

Checks if `role` is authorized for `ability`.
"""
function role_has_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Bool
  try
    return haskey(params[Genie.PARAMS_ACL_KEY], string(role)) && # role is defined in ACL
            (ability == :any || # no ability required, just the right kind of role
              haskey(params[Genie.PARAMS_ACL_KEY][string(role)], string(ability)) ) # role has ability
  catch ex
    log("Invalid ACL", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    return false
  end
end


"""
    scopes_of_role_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Vector{Symbol}

Returns a `vector` of SQL scopes defined by the role and ability settings.
"""
function scopes_of_role_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Vector{Symbol}
  haskey(params[Genie.PARAMS_ACL_KEY], string(role)) &&
    haskey(params[Genie.PARAMS_ACL_KEY][string(role)], string(ability)) &&
    params[Genie.PARAMS_ACL_KEY][string(role)][string(ability)] != nothing ?
      map(scope -> Symbol(scope), params[Genie.PARAMS_ACL_KEY][string(role)][string(ability)]) :
      Symbol[]
end

end
