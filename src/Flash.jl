"""
Various utility functions for using across models, controllers and views.
"""
module Flash
using DocStringExtensionsMock

import Genie

export flash, flash_has_message


"""
$TYPEDSIGNATURES
"""
function init()
  Genie.Sessions.init()
end


"""
$TYPEDSIGNATURES

Returns the `flash` dict object associated with the current HTTP request.
"""
function flash()
  get(Genie.Requests.payload(), Genie.PARAMS_FLASH_KEY, "")
end


"""
$TYPEDSIGNATURES

Stores `value` onto the flash.
"""
function flash(value::Any) :: Nothing
  Genie.Sessions.set!(Genie.Sessions.session(Genie.Requests.payload()), Genie.PARAMS_FLASH_KEY, value)
  Genie.Requests.payload()[Genie.PARAMS_FLASH_KEY] = value

  nothing
end


"""
$TYPEDSIGNATURES

Checks if there's any value on the flash storage
"""
function flash_has_message() :: Bool
  ! isempty(flash())
end

end
