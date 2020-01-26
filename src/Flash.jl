"""
Various utility functions for using across models, controllers and views.
"""
module Flash

import Genie

export flash, flash_has_message


"""
    flash()

Returns the `flash` dict object associated with the current HTTP request.
"""
function flash()
  Genie.Requests.payload()[Genie.PARAMS_FLASH_KEY]
end


function flash(value::Any) :: Nothing
  Genie.Sessions.set!(Genie.Sessions.session(Genie.Requests.payload()), Genie.PARAMS_FLASH_KEY, value)
  Genie.Requests.payload()[Genie.PARAMS_FLASH_KEY] = value

  nothing
end


"""
    flash_has_message() :: Bool

Checks if there's any value on the flash storage
"""
function flash_has_message() :: Bool
  ! isempty(flash())
end

end
