module SearchLightSessionAdapter

using Sessions, Genie, Logger, Configuration, App, Migration, JSON, SearchLight

type StorageSession <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### fields
  id::Nullable{SearchLight.DbId}
  name::String
  val::String

  ### constructor
  StorageSession(;
    id = Nullable{SearchLight.DbId}(),
    name = "",
    val = ""
  ) = new("storage_sessions", "id", id, name, val)
end


"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the DB, using the configured SearchLight DB and returns it.
"""
function write(session::Sessions.Session) :: Sessions.Session
  try
    SearchLight.update_by_or_create!!(StorageSession(name = session.id, val = JSON.json(session.data)), :name)
  catch ex
    Logger.log("Error when serializing session in $(@__FILE__):$(@__LINE__)", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end

  session
end


"""
    read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
    read(session::Sessions.Session) :: Nullable{Sessions.Session}

Attempts to read from DB the session object.
"""
function read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
  try
    session_info = SearchLight.find_one_by!!(StorageSession, :name, session_id)
    session = Sessions.Session(session_info.name, JSON.parse(session_info.val))

    return isnull(session) ? Nullable{Sessions.Session}() : Nullable{Sessions.Session}(session)
  catch ex
    Logger.log("Can't read session", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    return Nullable{Sessions.Session}(write(Sessions.Session(session_id)))
  end
end
function read(session::Sessions.Session) :: Nullable{Sessions.Session}
  read(session.id)
end


### Migrations module

module Migrations

module CreateTableStorageSessions

import Migration: create_table, column, column_id, add_index, drop_table
using Configuration, App

"""

"""
function up()
  create_table(App.config.session_table) do
    [
      column_id()
      column(:name, :string, "UNIQUE", limit = 64)
      column(:val, :text)
    ]
  end

  add_index(App.config.session_table, :name)
end

function down()
  drop_table(App.config.session_table)
end

end # module CreateTableStorageSessions

end # module Migrations

end
