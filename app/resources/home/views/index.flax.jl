using Flax

function(params::Dict)
  d() do
    params[:message]
  end
end
