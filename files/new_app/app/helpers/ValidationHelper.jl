module ValidationHelper

using Genie, Genie.Context, SearchLight, SearchLight.Validation

export output_errors

function output_errors(params::Params, m::T, field::Symbol)::String where {T<:SearchLight.AbstractModel}
  v = ispayload(params) ? validate(m) : ModelValidator()

  haserrorsfor(v, field) ?
    """
      <div class="text-danger form-text">
        $(errors_to_string(v, field, separator = "<br/>\n", uppercase_first = true))
      </div>""" : ""
end

end