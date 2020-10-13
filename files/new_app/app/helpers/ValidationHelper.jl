module ValidationHelper

using Genie
using SearchLight.Validation

export output_errors

function output_errors(m, field::Symbol) :: String
  Validation.haserrorsfor(m, field) ? """<label class="control-label error label-danger">$(Validation.errors_to_string(m, field, "<br/>\n", uppercase_first = true))</label>""" : ""
end

end