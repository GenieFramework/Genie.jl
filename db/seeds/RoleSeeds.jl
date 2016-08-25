module RoleSeeds
using Genie, Model

function default_roles()
  for i in [:user, :admin, :editor, :blogger]
    role = Role()
    role.name = i

    Model.save!!(role)
  end
end

end