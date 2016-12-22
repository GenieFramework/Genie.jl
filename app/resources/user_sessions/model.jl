export UserSession, UserSessions

type UserSession <: AbstractModel
  _table_name::String
  _id::String

  id::Nullable{SearchLight.DbId}

  UserSession(;
    id = Nullable{SearchLight.DbId}()
  ) = new("usersessions", "id", id)
end

module UserSessions
using Genie
end
