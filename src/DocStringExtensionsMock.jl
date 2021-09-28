module DocStringExtensionsMock

#If we don' thave DocStringExtensions installed, make a fall-back that prevents an error:
using Pkg
#If DocStringExtensions is installed, use it:
if Base.find_package("DocStringEstensions")!==nothing
    using DocStringExtensions
else
  TYPEDSIGNATURES=""
  SIGNATURES=""
end

export SIGNATURES, TYPEDSIGNATURES

end