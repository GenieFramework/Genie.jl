"""
Various utility functions for using across models, controllers and views.
"""
module Flash

import Genie

export flash, flash_has_message


function init()
  Genie.Sessions.init()
end


"""
    flash()

Returns the `flash` dict object associated with the current HTTP request.
"""
function flash()
  get(Genie.Requests.payload(), Genie.Router.PARAMS_FLASH_KEY, "")
end


"""
    flash(value::Any) :: Nothing

Stores `value` onto the flash.
"""
function flash(value::Any) :: Nothing
  Genie.Sessions.set!(Genie.Sessions.session(Genie.Requests.payload()), Genie.Router.PARAMS_FLASH_KEY, value)
  Genie.Requests.payload()[Genie.Router.PARAMS_FLASH_KEY] = value

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
