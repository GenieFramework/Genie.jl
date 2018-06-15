module ViewHelper

using Genie, Genie.Helpers

export output_flash

function output_flash(params::Dict{Symbol,Any}) :: String
  ! isempty( flash(params) ) ? """<div class="form-group alert alert-info">$(flash(params))</div>""" : ""
end

end
