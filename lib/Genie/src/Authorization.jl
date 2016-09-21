module Authorization
using Genie, Model, Authentication, Helpers, App, Util
export is_authorized, with_authorization

function is_authorized(ability::Symbol, params::Dict{Symbol,Any})
  Authentication.is_authenticated(session(params)) || return false
  user_role = Model.relationship_data!!(expand_nullable(current_user(session(params)), default = User()), Role, RELATIONSHIP_BELONGS_TO).name
  role_has_ability(user_role, ability, params)
end

function with_authorization(f::Function, ability::Symbol, fallback::Function, params::Dict{Symbol,Any})
  if ! is_authorized(ability, params)
    fallback(params)
  else
    f()
  end
end

function role_has_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any})
  haskey(params[Genie.PARAMS_ACL_KEY], string(role)) && # role is defined in ACL
    (ability == :any || # no ability required, just the right kind of role
    haskey(params[Genie.PARAMS_ACL_KEY][string(role)], string(ability)) ) # role has ability
end

end