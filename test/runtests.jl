using CounterfactualExplanations
using CounterfactualExplanations.Data
using CounterfactualExplanations.DataPreprocessing
using CounterfactualExplanations.Models
using Printf
using PythonCall
using Random
using TaijaInteroperability
using Test

include("utils.jl")

synthetic = _load_synthetic()

@testset "TaijaInteroperability.jl" begin
    include("pytorch.jl")
end
