module ViewHelper

using Genie, Validation, Helpers, App

export output_errors, output_flash

function output_errors(m, field::Symbol) :: String
  Validation.has_errors_for(m, field) ? """<label class="control-label error label-danger">$(Validation.errors_to_string(m, field, "<br/>\n", upper_case_first = true))</label>""" : ""
end

function output_flash(params::Dict{Symbol,Any}) :: String
  ! isempty( flash(params) ) ? """<div class="form-group alert alert-info">$(flash(params))</div>""" : ""
end

end
