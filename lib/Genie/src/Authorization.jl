module Authorization

using Genie, SearchLight, Authentication, Helpers, App, Util, Logger

export is_authorized, with_authorization

function is_authorized(ability::Symbol, params::Dict{Symbol,Any}) :: Bool
  Authentication.is_authenticated(session(params)) || return false
  user_role = expand_nullable( expand_nullable(current_user(session(params)), User()).role, :user )
  role_has_ability(user_role, ability, params)
end

function with_authorization(f::Function, ability::Symbol, fallback::Function, params::Dict{Symbol,Any})
  if ! is_authorized(ability, params)
    fallback(params)
  else
    user_role = expand_nullable( expand_nullable(current_user(session(params)), User()).role, :user )
    f(scopes_of_role_ability(user_role, ability, params))
  end
end

function role_has_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Bool
  try
    return haskey(params[Genie.PARAMS_ACL_KEY], string(role)) && # role is defined in ACL
            (ability == :any || # no ability required, just the right kind of role
              haskey(params[Genie.PARAMS_ACL_KEY][string(role)], string(ability)) ) # role has ability
  catch ex
    Logger.log(ex, :err)
    return false
  end
end

function scopes_of_role_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Vector{Symbol}
  haskey(params[Genie.PARAMS_ACL_KEY], string(role)) &&
    haskey(params[Genie.PARAMS_ACL_KEY][string(role)], string(ability)) &&
    params[Genie.PARAMS_ACL_KEY][string(role)][string(ability)] != nothing ?
      map(scope -> Symbol(scope), params[Genie.PARAMS_ACL_KEY][string(role)][string(ability)]) :
      Symbol[]
end

end
