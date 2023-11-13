module TaijaInteroperability

using PackageExtensionCompat
function __init__()
    @require_extensions
end

include("CounterfactualExplanations/CounterfactualExplanations.jl")

end
