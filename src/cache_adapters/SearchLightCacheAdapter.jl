module SearchLightCacheAdapter

using Genie, Logger, App, SearchLight, Util


type StorageCache <: AbstractModel
  ### internals
  _table_name::String
  _id::String

  ### fields
  id::Nullable{SearchLight.DbId}
  name::String
  val::String
  expires_at::Int

  ### constructor
  StorageCache(;
    id = Nullable{SearchLight.DbId}(),
    name = "",
    val = "",
    expires_at = time_to_unixtimestamp()
  ) = new("storage_caches", "id", id, name, val, expires_at)
end


"""
    to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Nothing

Persists `content` onto the DB under the `key` key.
"""
function to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Nothing
  try
    io = IOBuffer()
    serialize(io, content)

    SearchLight.update_by_or_create!!(StorageCache(name = key, val = base64encode(io.data), expires_at = time_to_unixtimestamp()), :name)
  catch ex
    Logger.log("Error when serializing cache in $(@__FILE__):$(@__LINE__)", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end

  nothing
end


"""
    from_cache(key::Union{String,Symbol}, expiration::Int) :: Nullable

Retrieves from cache the object stored under the `key` key if the `expiration` delta (in seconds) is in the future.
"""
function from_cache(key::Union{String,Symbol}, expiration::Int; dir = "") :: Nullable
  try
    cache_info = SearchLight.find_one_by!!(StorageCache, :name, key)

    App.config.log_cache && Logger.log("Found cache for $key", :info)

    cache_info.expires_at + expiration < time_to_unixtimestamp() && return Nullable()

    io = IOBuffer()
    io.data = base64decode(cache_info.val)
    io.size = size(io.data)[1]
    seekstart(io)
    cache = deserialize(io)

    Nullable(cache)
  catch ex
    Logger.log("Can't read cache", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    Nullable()
  end
end


"""
    purge(key::Union{String,Symbol}) :: Nothing

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir = "") :: Nothing
  cache_info = SearchLight.find_one_by!!(StorageCache, :name, key)
  SearchLight.delete(cache_info)

  nothing
end


"""
    purge_all() :: Nothing

Removes all cached data.
"""
function purge_all(; dir = "") :: Nothing
  SearchLight.delete_all(StorageCache, truncate = true, reset_sequence = true)

  nothing
end


"""
    cache_path(key::Union{String,Symbol}; dir = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Union{String,Symbol}; dir = "") :: String
  error("Not applicable!")
end



### Migrations module

module Migrations

module CreateTableStorageCaches

import Migration: create_table, column, column_id, add_index, drop_table

using Configuration, App

"""

"""
function up()
  create_table(App.config.cache_table) do
    [
    column_id()
    column(:name, :string, "UNIQUE", limit = 64)
    column(:val, :text)
    column(:expires_at, :integer)
    ]
  end

  add_index(App.config.cache_table, :expires_at)
end

function down()
  drop_table(App.config.cache_table)
end

end # module CreateTableStorageCaches

end # module Migrations

end
