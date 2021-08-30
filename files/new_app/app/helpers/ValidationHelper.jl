module ValidationHelper

using Genie, SearchLight, SearchLight.Validation

export output_errors

function output_errors(m::T, field::Symbol)::String where {T<:SearchLight.AbstractModel}
  v = ispayload() ? validate(m) : ModelValidator()

  haserrorsfor(v, field) ?
    """
      <div class="text-danger form-text">
        $(errors_to_string(v, field, separator = "<br/>\n", uppercase_first = true))
      </div>""" : ""
end

end