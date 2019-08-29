module ViewHelper

using Genie, Genie.Flash, Genie.Router

export output_flash

function output_flash() :: String
  flash_has_message() ? """<div class="form-group alert alert-info">$(flash())</div>""" : ""
end

end